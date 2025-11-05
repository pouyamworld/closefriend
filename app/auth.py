from datetime import datetime, timedelta, timezone
import hmac
import hashlib
import jwt
from passlib.context import CryptContext
from sqlalchemy.orm import Session
from google.oauth2 import id_token as google_id_token
from google.auth.transport import requests as google_requests
from .config import get_settings
from . import models

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
settings = get_settings()
ALGORITHM = "HS256"

# Password

def hash_password(password: str) -> str:
    return pwd_context.hash(password)

def verify_password(plain_password: str, password_hash: str) -> bool:
    return pwd_context.verify(plain_password, password_hash)

# JWT

def create_access_token(subject: str | int, expires_minutes: int | None = None) -> str:
    expire = datetime.now(timezone.utc) + timedelta(minutes=expires_minutes or settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    payload = {"sub": str(subject), "exp": expire}
    return jwt.encode(payload, settings.SECRET_KEY, algorithm=ALGORITHM)

def decode_token(token: str) -> dict:
    return jwt.decode(token, settings.SECRET_KEY, algorithms=[ALGORITHM])

# Google ID token verification

def verify_google_id_token(id_token: str) -> dict:
    if not settings.GOOGLE_CLIENT_ID:
        raise ValueError("GOOGLE_CLIENT_ID is not configured")
    req = google_requests.Request()
    info = google_id_token.verify_oauth2_token(id_token, req, settings.GOOGLE_CLIENT_ID)
    return info

# Telegram Login verification

def verify_telegram_auth(data: dict) -> bool:
    token = settings.TELEGRAM_BOT_TOKEN
    if not token:
        raise ValueError("TELEGRAM_BOT_TOKEN is not configured")
    secret_key = hashlib.sha256(token.encode()).digest()

    check_hash = data.get("hash")
    data_check_arr = []
    for key in sorted(k for k in data.keys() if k != "hash"):
        data_check_arr.append(f"{key}={data[key]}")
    data_check_string = "\n".join(data_check_arr)
    hmac_hash = hmac.new(secret_key, msg=data_check_string.encode(), digestmod=hashlib.sha256).hexdigest()

    if not hmac.compare_digest(hmac_hash, check_hash):
        return False

    # freshness check
    try:
        auth_date = int(data.get("auth_date", 0))
    except Exception:
        auth_date = 0
    if auth_date:
        now = int(datetime.now(timezone.utc).timestamp())
        if now - auth_date > settings.TELEGRAM_AUTH_MAX_AGE:
            return False
    return True
