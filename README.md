## CloseFriend FastAPI Backend

### Features
- Email signup with verification code
- Email/password login with JWT
- Google sign-in (ID token verification)
- Telegram sign-in (Login Widget hash validation)
- Dashboard endpoint to accept an array of close-friend IDs with timestamp

### Requirements
- Python 3.11+
- Docker (for Postgres and app container)

### Local (native) setup
1. Create and activate a virtualenv
```bash
python3 -m venv .venv
source .venv/bin/activate
```
2. Install dependencies
```bash
pip install -r requirements.txt
```
3. Start Postgres via Docker
```bash
docker compose up -d postgres
```
4. Copy env and set values
```bash
cp .env.example .env
# Ensure DATABASE_URL is Postgres, e.g.:
# DATABASE_URL=postgresql+psycopg://postgres:postgres@localhost:5432/closefriend
```
5. Run server
```bash
uvicorn app.main:app --reload
```

### Full Docker setup (app + postgres)
1. Optional: export env vars (or create a .env used by compose variable expansion)
```bash
export SECRET_KEY=change-me
export ACCESS_TOKEN_EXPIRE_MINUTES=60
export BACKEND_CORS_ORIGINS=http://localhost:3000
# export GOOGLE_CLIENT_ID=...
# export TELEGRAM_BOT_TOKEN=...
```
2. Build and run
```bash
docker compose up -d --build
```
- App: http://localhost:8000
- Postgres: localhost:5432

The app container uses `DATABASE_URL=postgresql+psycopg://postgres:postgres@postgres:5432/closefriend` to connect to the DB service.

### Environment Variables
- SECRET_KEY: JWT signing secret
- ACCESS_TOKEN_EXPIRE_MINUTES: e.g. 60
- GOOGLE_CLIENT_ID: OAuth client ID to validate ID tokens
- TELEGRAM_BOT_TOKEN: Bot token used to validate Telegram Login Widget
- BACKEND_CORS_ORIGINS: Comma-separated origins (e.g. http://localhost:3000)
- DATABASE_URL: SQLAlchemy URL (default inside container points to `postgres` service)

### Notes
- Email sending is logged to console for development. Replace the `email_service` with a real SMTP or provider in production.
- Database tables are created automatically on startup.
