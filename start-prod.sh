#!/bin/bash
# Production startup script using Gunicorn

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

# Activate virtual environment if it exists
if [ -d ".venv" ]; then
    source .venv/bin/activate
fi

# Number of workers (2 x CPU cores + 1)
WORKERS=${WORKERS:-4}

# Run with Gunicorn + Uvicorn workers (production)
echo "Starting CloseFriend API server in production mode..."
echo "Workers: $WORKERS"
echo ""
exec gunicorn app.main:app \
    --workers $WORKERS \
    --worker-class uvicorn.workers.UvicornWorker \
    --bind 0.0.0.0:8000 \
    --access-logfile - \
    --error-logfile - \
    --log-level info
