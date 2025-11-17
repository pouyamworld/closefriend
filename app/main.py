from datetime import datetime, timedelta
import random
from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.routing import APIRoute
from sqlalchemy.orm import Session
from email_validator import validate_email, EmailNotValidError

from .config import get_settings
from .database import Base, engine, get_db
from . import models
from . import schemas
from .auth import (
    hash_password,
    verify_password,
    create_access_token,
    verify_google_id_token,
    pwd_context
)
from .email_service import send_verification_code
from .deps import get_current_user

# -------------------------------------------------------------------
# Settings
# -------------------------------------------------------------------

settings = get_settings()

openapi_tags = [
    {"name": "Auth", "description": "Authentication and registration endpoints"},
    {"name": "Dashboard", "description": "User dashboard and close-friend events"},
]

app = FastAPI(
    title="CloseFriend Backend",
    description="CloseFriend backend API — authentication, verification and dashboard endpoints.",
    version="1.0.0",
    docs_url="/swagger",
    redoc_url="/redoc",
    openapi_url="/openapi.json",
    contact={"name": "CloseFriend Team", "email": "ilyanozary.dynamic@gmail.com"},
    openapi_tags=openapi_tags
)

# -------------------------------------------------------------------
# CORS
# -------------------------------------------------------------------

origins = settings.cors_origin_list
if origins:
    app.add_middleware(
        CORSMiddleware,
        allow_origins=origins,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

# -------------------------------------------------------------------
# Startup
# -------------------------------------------------------------------

@app.on_event("startup")
def on_startup():
    Base.metadata.create_all(bind=engine)

    if settings.is_production:
        missing = []
        if not settings.SECRET_KEY or settings.SECRET_KEY == "change-me":
            missing.append("SECRET_KEY")
        if not settings.GOOGLE_CLIENT_ID:
            missing.append("GOOGLE_CLIENT_ID")
        if not settings.TELEGRAM_BOT_TOKEN:
            missing.append("TELEGRAM_BOT_TOKEN")
        if missing:
            raise RuntimeError(f"Missing required env in prod: {', '.join(missing)}")

# -------------------------------------------------------------------
# Helpers
# -------------------------------------------------------------------

def _generate_code(length: int = 6) -> str:
    return "".join(str(random.randint(0, 9)) for _ in range(length))

# -------------------------------------------------------------------
# HOME Route – List All Endpoints
# -------------------------------------------------------------------

@app.get("/", tags=["Home"])
def home():
    routes = []
    for route in app.routes:
        if isinstance(route, APIRoute):
            routes.append({
                "path": route.path,
                "methods": list(route.methods),
                "name": route.name,
                "description": route.description or "",
                "tags": route.tags or []
            })

    return {
        "project": "CloseFriend Backend",
        "version": "1.0.0",
        "total_routes": len(routes),
        "routes": routes
    }

# -------------------------------------------------------------------
# AUTH ROUTES
# -------------------------------------------------------------------

@app.post("/auth/register/start", response_model=dict, tags=["Auth"])
def register_start(payload: schemas.RegisterStartIn, db: Session = Depends(get_db)):
    # Validate email
    try:
        validate_email(str(payload.email))
    except EmailNotValidError as e:
        raise HTTPException(status_code=400, detail=str(e))

    # Check existing user
    user = db.query(models.User).filter(models.User.email == str(payload.email)).first()

    if user and user.is_verified:
        raise HTTPException(status_code=400, detail="Email already registered")

    if not user:
        user = models.User(email=str(payload.email), is_verified=False)
        db.add(user)
        db.flush()

    # Update password hash (covers both new + unverified users)
    user.password_hash = hash_password(payload.password)

    # Create verification code
    code = _generate_code()
    code_hash = pwd_context.hash(code)
    expires_at = datetime.utcnow() + timedelta(minutes=10)

    v = models.EmailVerificationCode(
        user_id=user.id,
        code_hash=code_hash,
        expires_at=expires_at
    )
    db.add(v)
    db.commit()

    send_verification_code(user.email, code)

    return {"message": "Verification code sent"}


@app.post("/auth/register/verify", response_model=schemas.Token, tags=["Auth"])
def register_verify(payload: schemas.RegisterVerifyIn, db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.email == str(payload.email)).first()
    if not user:
        raise HTTPException(status_code=400, detail="User not found")

    if user.is_verified:
        raise HTTPException(status_code=400, detail="Already verified")

    # Latest code
    code_row = (
        db.query(models.EmailVerificationCode)
        .filter(models.EmailVerificationCode.user_id == user.id)
        .order_by(models.EmailVerificationCode.created_at.desc())
        .first()
    )

    if not code_row or code_row.expires_at < datetime.utcnow():
        raise HTTPException(status_code=400, detail="Code expired or not found")

    if not pwd_context.verify(payload.code, code_row.code_hash):
        raise HTTPException(status_code=400, detail="Invalid code")

    # Mark user verified
    user.is_verified = True
    db.add(user)
    db.commit()

    token = create_access_token(user.id)
    return schemas.Token(access_token=token)


@app.post("/auth/login", response_model=schemas.Token, tags=["Auth"])
def login(payload: schemas.LoginIn, db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.email == str(payload.email)).first()

    if not user or not user.password_hash:
        raise HTTPException(status_code=400, detail="Invalid credentials")

    if not user.is_verified:
        raise HTTPException(status_code=400, detail="Email not verified")

    if not verify_password(payload.password, user.password_hash):
        raise HTTPException(status_code=400, detail="Invalid credentials")

    token = create_access_token(user.id)
    return schemas.Token(access_token=token)


@app.post("/auth/google", response_model=schemas.Token, tags=["Auth"])
def google_sign_in(payload: schemas.GoogleSignInIn, db: Session = Depends(get_db)):
    try:
        info = verify_google_id_token(payload.id_token)
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid Google token")

    sub = info.get("sub")
    email = info.get("email")

    if not sub:
        raise HTTPException(status_code=400, detail="Invalid Google token payload")

    user = db.query(models.User).filter(models.User.google_sub == sub).first()

    if not user and email:
        user = db.query(models.User).filter(models.User.email == email).first()

    # Create or update
    if not user:
        user = models.User(
            email=email or f"google_{sub}@google.local",
            google_sub=sub,
            is_verified=True
        )
        db.add(user)
    else:
        user.google_sub = sub
        user.is_verified = True
        if email and user.email != email:
            user.email = email

    db.commit()
    token = create_access_token(user.id)
    return schemas.Token(access_token=token)


@app.post("/auth/telegram", response_model=schemas.Token, tags=["Auth"])
def telegram_sign_in(payload: schemas.TelegramSignInIn, db: Session = Depends(get_db)):
    data = payload.model_dump()

    from .auth import verify_telegram_auth
    try:
        ok = verify_telegram_auth(data)
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

    if not ok:
        raise HTTPException(status_code=400, detail="Invalid Telegram signature")

    tg_id = str(payload.id)

    user = db.query(models.User).filter(models.User.telegram_id == tg_id).first()

    if not user:
        synthetic_email = f"tg_{tg_id}@telegram.local"
        existing = (
            db.query(models.User)
            .filter(models.User.email == synthetic_email)
            .first()
        )

        if existing:
            synthetic_email = f"tg_{tg_id}_{int(datetime.utcnow().timestamp())}@telegram.local"

        user = models.User(
            email=synthetic_email,
            telegram_id=tg_id,
            is_verified=True
        )
        db.add(user)
        db.commit()

    token = create_access_token(user.id)
    return schemas.Token(access_token=token)

# -------------------------------------------------------------------
# Dashboard
# -------------------------------------------------------------------

@app.post("/dashboard/close-friends",
          response_model=schemas.CloseFriendEventOut,
          tags=["Dashboard"])
async def add_close_friends(
    payload: schemas.CloseFriendsIn,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    event = models.CloseFriendEvent(
        user_id=current_user.id,
        friend_ids={"friend_ids": payload.friend_ids},
    )
    db.add(event)
    db.commit()
    db.refresh(event)
    return event
