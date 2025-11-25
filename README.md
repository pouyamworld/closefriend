## CloseFriend FastAPI Backend

### Features
- Email signup with verification code
- Email/password login with JWT
- Google sign-in (ID token verification)
- Telegram sign-in (Login Widget hash validation)
- Dashboard endpoint to accept an array of close-friend IDs with timestamp
- Interactive API documentation with Swagger UI

### Requirements
- Python 3.11+
- PostgreSQL database (or SQLite for development)

---

## ⚠️ Security Notice - Docker

**IMPORTANT:** If you previously used Docker and experienced high CPU usage (700%+) or crypto mining activity, please read [DOCKER-SECURITY.md](DOCKER-SECURITY.md) immediately.

The Dockerfile and docker-compose.yml have been updated with critical security fixes:
- ✅ Resource limits (CPU capped at 50%)
- ✅ Non-root user execution
- ✅ Read-only filesystem
- ✅ Dropped all dangerous capabilities
- ✅ Removed curl/wget to prevent malware downloads

**Recommended:** Use `./setup-server.sh` instead of Docker for production.

---

## 🚀 Quick Server Deployment (Automated)

**For Ubuntu/Debian servers - One command setup:**

```bash
git clone https://github.com/pouyamworld/closefriend.git
cd closefriend
./setup-server.sh
```

This script automatically:
- ✅ Installs Python 3.11/3.12, PostgreSQL, Nginx
- ✅ Creates and configures database
- ✅ Sets up Python virtual environment
- ✅ Generates secure configuration
- ✅ Creates systemd service
- ✅ Configures Nginx reverse proxy
- ✅ Sets up firewall
- ✅ (Optional) Installs SSL certificate

📖 **Full deployment guide:** See [DEPLOYMENT.md](DEPLOYMENT.md)

---

## Setup and Deployment

### Option 1: Automated Server Setup (Production)

**Recommended for production deployment on Ubuntu/Debian servers.**

See [DEPLOYMENT.md](DEPLOYMENT.md) for complete instructions.

Quick start:
```bash
./setup-server.sh
```

### Option 2: Local Development (without Docker)

This is the recommended way to run and deploy the project.

#### 1. Install Python dependencies
```bash
python3 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
```

#### 2. Setup database

**Option A: PostgreSQL (recommended for production)**

Install PostgreSQL locally:
```bash
# macOS
brew install postgresql@16
brew services start postgresql@16

# Ubuntu/Debian
sudo apt-get install postgresql postgresql-contrib
sudo systemctl start postgresql
```

Create database:
```bash
createdb closefriend
# Or using psql:
# psql -U postgres -c "CREATE DATABASE closefriend;"
```

**Option B: SQLite (development only)**

No installation needed - just set `DATABASE_URL=sqlite:///./closefriend.db` in `.env`

#### 3. Configure environment variables
```bash
cp .env.example .env
```

Edit `.env` and set:
- `SECRET_KEY` - Generate a random secret key (e.g., using `openssl rand -hex 32`)
- `DATABASE_URL` - Your database connection string
- `BACKEND_CORS_ORIGINS` - Allowed origins for your frontend
- Optional: `GOOGLE_CLIENT_ID`, `TELEGRAM_BOT_TOKEN`

Example `.env` for local PostgreSQL:
```env
SECRET_KEY=your-secret-key-here
DATABASE_URL=postgresql+psycopg://postgres:postgres@localhost:5432/closefriend
BACKEND_CORS_ORIGINS=http://localhost:3000
ENVIRONMENT=dev
```

#### 4. Run the server
```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

The API will be available at http://localhost:8000

#### 5. Access API documentation
- **Swagger UI**: http://localhost:8000/swagger
- **ReDoc**: http://localhost:8000/redoc
- **OpenAPI JSON**: http://localhost:8000/openapi.json

---

### Option 2: Production Deployment (without Docker)

#### Deploy to any VPS or cloud platform:

1. Install Python 3.11+ and PostgreSQL on your server

2. Clone the repository:
```bash
git clone https://github.com/pouyamworld/closefriend.git
cd closefriend
```

3. Setup virtual environment and install dependencies:
```bash
python3 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
```

4. Create and configure `.env`:
```bash
cp .env.example .env
nano .env  # or vim .env
```

Set production values:
```env
SECRET_KEY=<generate-strong-random-key>
DATABASE_URL=postgresql+psycopg://user:password@localhost:5432/closefriend
BACKEND_CORS_ORIGINS=https://yourdomain.com
ENVIRONMENT=prod
GOOGLE_CLIENT_ID=your-google-client-id
TELEGRAM_BOT_TOKEN=your-telegram-bot-token
```

5. Run with production server:

**Using Uvicorn directly:**
```bash
uvicorn app.main:app --host 0.0.0.0 --port 8000 --workers 4
```

**Using Gunicorn with Uvicorn workers (recommended):**
```bash
pip install gunicorn
gunicorn app.main:app -w 4 -k uvicorn.workers.UvicornWorker --bind 0.0.0.0:8000
```

**Using systemd service (recommended for production):**

Create `/etc/systemd/system/closefriend.service`:
```ini
[Unit]
Description=CloseFriend FastAPI Application
After=network.target postgresql.service

[Service]
Type=notify
User=www-data
Group=www-data
WorkingDirectory=/path/to/closefriend
Environment="PATH=/path/to/closefriend/.venv/bin"
ExecStart=/path/to/closefriend/.venv/bin/gunicorn app.main:app -w 4 -k uvicorn.workers.UvicornWorker --bind 0.0.0.0:8000
Restart=always

[Install]
WantedBy=multi-user.target
```

Enable and start:
```bash
sudo systemctl daemon-reload
sudo systemctl enable closefriend
sudo systemctl start closefriend
```

6. Setup reverse proxy with Nginx:

```nginx
server {
    listen 80;
    server_name yourdomain.com;

    location / {
        proxy_pass http://localhost:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

7. Setup SSL with Let's Encrypt:
```bash
sudo apt-get install certbot python3-certbot-nginx
sudo certbot --nginx -d yourdomain.com
```

---

### Option 3: Docker Setup (⚠️ Not Recommended for Production)

**Security Warning:** Docker setup has been secured but may still be vulnerable. Use `setup-server.sh` for production.

If you must use Docker, we've added critical security measures:
- CPU限制 at 50% of one core
- Memory limit of 512MB
- Read-only filesystem
- Non-root user execution
- No dangerous capabilities

See [DOCKER-SECURITY.md](DOCKER-SECURITY.md) for details.

#### Secure Docker deployment:

```bash
# IMPORTANT: Pull latest security updates first
git pull origin main

# Clean rebuild (no cache)
docker compose down -v
docker system prune -a --volumes --force
docker compose build --no-cache
docker compose up -d

# Monitor for suspicious activity
./docker-monitor.sh
```

#### Start only PostgreSQL:
```bash
docker compose up -d postgres
```

Then run the app locally (recommended):
```bash
source .venv/bin/activate
uvicorn app.main:app --reload
```

---

### Environment Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `SECRET_KEY` | JWT signing secret | - | Yes |
| `DATABASE_URL` | SQLAlchemy database URL | `postgresql+psycopg://postgres:postgres@localhost:5432/closefriend` | Yes |
| `ACCESS_TOKEN_EXPIRE_MINUTES` | JWT expiration time | `60` | No |
| `BACKEND_CORS_ORIGINS` | Comma-separated CORS origins | - | No |
| `GOOGLE_CLIENT_ID` | Google OAuth client ID | - | No |
| `TELEGRAM_BOT_TOKEN` | Telegram bot token | - | No |
| `TELEGRAM_AUTH_MAX_AGE` | Telegram auth validity (seconds) | `300` | No |
| `ENVIRONMENT` | Environment (`dev` or `prod`) | `dev` | No |

**Database URL Examples:**
- PostgreSQL: `postgresql+psycopg://user:password@localhost:5432/dbname`
- SQLite (dev only): `sqlite:///./closefriend.db`

---

### API Endpoints

#### Authentication
- `POST /auth/register/start` - Start email registration (sends verification code)
- `POST /auth/register/verify` - Verify email with code and complete registration
- `POST /auth/login` - Login with email and password
- `POST /auth/google` - Sign in with Google ID token
- `POST /auth/telegram` - Sign in with Telegram Login Widget

#### Dashboard
- `POST /dashboard/close-friends` - Add close friends event (requires authentication)

See full interactive documentation at `/swagger` when running the server.

---

### Notes

- Email sending is logged to console for development. Replace `email_service.py` with a real SMTP or email provider in production.
- Database tables are created automatically on startup via SQLAlchemy.
- For production, always use a strong `SECRET_KEY` and set `ENVIRONMENT=prod`.
- SQLite is suitable for development only - use PostgreSQL for production.
