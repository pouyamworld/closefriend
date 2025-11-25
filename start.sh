#!/bin/bash
# Simple startup script for development

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

# Activate virtual environment if it exists
if [ -d ".venv" ]; then
    source .venv/bin/activate
fi

# Run with uvicorn (development)
echo "Starting CloseFriend API server..."
echo "Swagger UI: http://localhost:8000/swagger"
echo "API Docs: http://localhost:8000/redoc"
echo ""
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
