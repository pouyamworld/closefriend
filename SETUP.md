# Quick Setup Guide

## Development Setup (Recommended)

### 1. Install Dependencies
```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

### 2. Configure Environment
```bash
cp .env.example .env
```

Edit `.env` and set at minimum:
```env
SECRET_KEY=your-random-secret-key-here
DATABASE_URL=sqlite:///./closefriend.db  # Or PostgreSQL URL
```

Generate a secret key:
```bash
python3 -c "import secrets; print(secrets.token_hex(32))"
```

### 3. Run the Server
```bash
./start.sh
# Or manually:
# uvicorn app.main:app --reload
```

### 4. Test the API
- API: http://localhost:8000
- **Swagger UI**: http://localhost:8000/swagger
- ReDoc: http://localhost:8000/redoc
- OpenAPI spec: http://localhost:8000/openapi.json

---

## Production Deployment

### Quick Deploy to VPS

1. SSH to your server and install requirements:
```bash
sudo apt update
sudo apt install -y python3.11 python3.11-venv postgresql postgresql-contrib nginx
```

2. Clone and setup:
```bash
git clone https://github.com/pouyamworld/closefriend.git
cd closefriend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

3. Setup PostgreSQL:
```bash
sudo -u postgres createdb closefriend
sudo -u postgres psql -c "ALTER USER postgres PASSWORD 'your-password';"
```

4. Configure environment:
```bash
cp .env.example .env
nano .env
```

Set:
```env
SECRET_KEY=<generate-with-python3 -c "import secrets; print(secrets.token_hex(32))">
DATABASE_URL=postgresql+psycopg://postgres:your-password@localhost:5432/closefriend
BACKEND_CORS_ORIGINS=https://yourdomain.com
ENVIRONMENT=prod
```

5. Test run:
```bash
./start-prod.sh
```

6. Setup systemd service (see README.md for full config)

7. Setup Nginx reverse proxy (see README.md)

---

## Database Options

### SQLite (Development)
```env
DATABASE_URL=sqlite:///./closefriend.db
```
- No installation needed
- Single file database
- Not suitable for production

### PostgreSQL (Production)
```env
DATABASE_URL=postgresql+psycopg://user:password@host:5432/dbname
```
- Production-ready
- Better performance
- Concurrent connections

---

## Testing the API

### Register a new user:
```bash
curl -X POST http://localhost:8000/auth/register/start \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com", "password": "password123"}'
```

Check your console for the verification code, then:
```bash
curl -X POST http://localhost:8000/auth/register/verify \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com", "code": "123456"}'
```

### Login:
```bash
curl -X POST http://localhost:8000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com", "password": "password123"}'
```

Or use the **interactive Swagger UI** at http://localhost:8000/swagger

---

## Troubleshooting

### Swagger UI shows 404
The container needs to be rebuilt with the new code:
```bash
docker compose down
docker compose up -d --build
```

Or run without Docker:
```bash
source .venv/bin/activate
uvicorn app.main:app --reload
```

### Database connection errors
- Check `DATABASE_URL` in `.env`
- Ensure PostgreSQL is running: `sudo systemctl status postgresql`
- Test connection: `psql postgresql://user:password@localhost:5432/closefriend`

### Import errors
```bash
pip install -r requirements.txt
```

### Permission denied on start.sh
```bash
chmod +x start.sh start-prod.sh
```
