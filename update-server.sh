#!/bin/bash
set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}Updating CloseFriend Backend...${NC}"

APP_DIR="/var/www/closefriend"

if [ ! -d "$APP_DIR" ]; then
    echo -e "${YELLOW}Error: Application not found at $APP_DIR${NC}"
    echo -e "${YELLOW}Please run setup-server.sh first${NC}"
    exit 1
fi

cd $APP_DIR

# Pull latest code
echo -e "${YELLOW}[1/4] Pulling latest code...${NC}"
git pull || echo "Not a git repo, skipping..."

# Update dependencies
echo -e "${YELLOW}[2/4] Updating dependencies...${NC}"
source .venv/bin/activate
pip install -r requirements.txt -q --upgrade

# Run database migrations (if any)
echo -e "${YELLOW}[3/4] Checking database...${NC}"
# Add migration commands here if needed

# Restart service
echo -e "${YELLOW}[4/4] Restarting service...${NC}"
sudo systemctl restart closefriend

# Check status
echo ""
echo -e "${GREEN}✓ Update complete!${NC}"
echo ""
sudo systemctl status closefriend --no-pager | head -10
