#!/bin/bash
# Quick test script to verify setup

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

APP_DIR="/var/www/closefriend"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║           CloseFriend Setup Verification                    ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Check if app directory exists
if [ ! -d "$APP_DIR" ]; then
    echo -e "${RED}✗ Application directory not found: $APP_DIR${NC}"
    echo -e "${YELLOW}  Run setup-server.sh first${NC}"
    exit 1
fi

cd $APP_DIR

# Check virtual environment
echo -n "Checking virtual environment... "
if [ -d ".venv" ]; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗ Not found${NC}"
    exit 1
fi

# Activate venv
source .venv/bin/activate

# Check Python version
echo -n "Python version... "
PYTHON_VERSION=$(python --version 2>&1)
echo -e "${GREEN}✓ $PYTHON_VERSION${NC}"

# Check critical packages
echo ""
echo "Checking Python packages:"

for pkg in fastapi uvicorn gunicorn sqlalchemy pydantic; do
    echo -n "  - $pkg... "
    if python -c "import $pkg" 2>/dev/null; then
        VERSION=$(python -c "import $pkg; print(getattr($pkg, '__version__', 'installed'))" 2>/dev/null)
        echo -e "${GREEN}✓ $VERSION${NC}"
    else
        echo -e "${RED}✗ Not installed${NC}"
    fi
done

# Check if app can be imported
echo ""
echo -n "Checking app import... "
if python -c "from app.main import app; print('OK')" 2>/dev/null; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗ Failed${NC}"
    echo ""
    echo -e "${YELLOW}Attempting to import with error details:${NC}"
    python -c "from app.main import app" 2>&1 | head -20
    exit 1
fi

# Check .env file
echo -n "Checking .env file... "
if [ -f ".env" ]; then
    echo -e "${GREEN}✓${NC}"
    
    # Check critical variables
    echo ""
    echo "Environment variables:"
    for var in SECRET_KEY DATABASE_URL; do
        echo -n "  - $var... "
        if grep -q "^$var=" .env && ! grep -q "^$var=\$" .env && ! grep -q "^$var=$" .env; then
            echo -e "${GREEN}✓ Set${NC}"
        else
            echo -e "${RED}✗ Not set or empty${NC}"
        fi
    done
else
    echo -e "${RED}✗ Not found${NC}"
fi

# Check PostgreSQL
echo ""
echo -n "Checking PostgreSQL... "
if systemctl is-active --quiet postgresql; then
    echo -e "${GREEN}✓ Running${NC}"
    
    # Try to connect
    echo -n "  Testing database connection... "
    DB_URL=$(grep "^DATABASE_URL=" .env | cut -d'=' -f2-)
    if python -c "
import sqlalchemy as sa
import sys
try:
    engine = sa.create_engine('$DB_URL')
    with engine.connect() as conn:
        conn.execute(sa.text('SELECT 1'))
    print('OK')
except Exception as e:
    print(f'FAILED: {e}', file=sys.stderr)
    sys.exit(1)
" 2>/dev/null; then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${RED}✗ Connection failed${NC}"
    fi
else
    echo -e "${RED}✗ Not running${NC}"
fi

# Check systemd service
echo ""
echo -n "Checking systemd service... "
if systemctl is-active --quiet closefriend; then
    echo -e "${GREEN}✓ Running${NC}"
elif systemctl is-enabled --quiet closefriend 2>/dev/null; then
    echo -e "${YELLOW}⚠ Enabled but not running${NC}"
    echo ""
    echo -e "${YELLOW}Service status:${NC}"
    sudo systemctl status closefriend --no-pager | head -10
else
    echo -e "${RED}✗ Not configured${NC}"
fi

# Check Nginx
echo ""
echo -n "Checking Nginx... "
if systemctl is-active --quiet nginx; then
    echo -e "${GREEN}✓ Running${NC}"
    
    echo -n "  Nginx config test... "
    if sudo nginx -t 2>&1 | grep -q "successful"; then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${RED}✗ Failed${NC}"
    fi
else
    echo -e "${RED}✗ Not running${NC}"
fi

# Test API endpoint
echo ""
echo -n "Testing API endpoint... "
sleep 2
if curl -s http://localhost:8000/openapi.json > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Responding${NC}"
else
    echo -e "${RED}✗ Not responding${NC}"
    echo ""
    echo -e "${YELLOW}Trying to start service manually for testing:${NC}"
    echo "  cd $APP_DIR"
    echo "  source .venv/bin/activate"
    echo "  uvicorn app.main:app --host 127.0.0.1 --port 8000"
fi

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                  Verification Complete                      ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Summary
echo -e "${GREEN}Summary:${NC}"
echo "  App Directory: $APP_DIR"
echo "  Python: $PYTHON_VERSION"
echo "  Virtual Env: .venv"
echo ""
echo -e "${YELLOW}Useful commands:${NC}"
echo "  sudo systemctl status closefriend"
echo "  sudo journalctl -u closefriend -f"
echo "  sudo systemctl restart closefriend"
