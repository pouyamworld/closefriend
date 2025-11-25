#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║      CloseFriend Backend - Automatic Server Setup           ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
    echo -e "${RED}⚠️  Please do not run as root. Run as a normal user with sudo access.${NC}"
    exit 1
fi

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    VERSION=$VERSION_ID
else
    echo -e "${RED}Cannot detect OS. This script supports Ubuntu/Debian.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Detected OS: $OS $VERSION${NC}"
echo ""

# Update system
echo -e "${YELLOW}[1/8] Updating system packages...${NC}"
sudo apt-get update -qq
sudo apt-get upgrade -y -qq

# Install dependencies
echo -e "${YELLOW}[2/8] Installing system dependencies...${NC}"
sudo apt-get install -y -qq \
    python3.11 \
    python3.11-venv \
    python3-pip \
    postgresql \
    postgresql-contrib \
    nginx \
    certbot \
    python3-certbot-nginx \
    git \
    curl \
    ufw

echo -e "${GREEN}✓ System dependencies installed${NC}"

# Setup PostgreSQL
echo -e "${YELLOW}[3/8] Configuring PostgreSQL...${NC}"

# Start PostgreSQL
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Create database and user
DB_NAME="closefriend"
DB_USER="closefriend_user"
DB_PASSWORD=$(python3 -c "import secrets; print(secrets.token_urlsafe(32))")

# Check if database exists
if sudo -u postgres psql -lqt | cut -d \| -f 1 | grep -qw $DB_NAME; then
    echo -e "${YELLOW}⚠️  Database '$DB_NAME' already exists${NC}"
else
    sudo -u postgres psql << EOF
CREATE DATABASE $DB_NAME;
CREATE USER $DB_USER WITH ENCRYPTED PASSWORD '$DB_PASSWORD';
GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;
ALTER DATABASE $DB_NAME OWNER TO $DB_USER;
\q
EOF
    echo -e "${GREEN}✓ PostgreSQL database '$DB_NAME' created${NC}"
fi

# Setup application directory
echo -e "${YELLOW}[4/8] Setting up application directory...${NC}"

APP_DIR="/var/www/closefriend"
if [ ! -d "$APP_DIR" ]; then
    sudo mkdir -p $APP_DIR
    sudo chown $USER:$USER $APP_DIR
fi

# Copy application files if not already there
if [ ! -f "$APP_DIR/app/main.py" ]; then
    echo -e "${YELLOW}   Copying application files...${NC}"
    cp -r . $APP_DIR/
    cd $APP_DIR
else
    cd $APP_DIR
    echo -e "${YELLOW}   Application files already exist, pulling latest changes...${NC}"
    git pull || echo "Not a git repository or no remote"
fi

# Create Python virtual environment
echo -e "${YELLOW}[5/8] Setting up Python virtual environment...${NC}"

if [ ! -d "$APP_DIR/.venv" ]; then
    python3.11 -m venv .venv
fi

source .venv/bin/activate
pip install --upgrade pip -q
pip install -r requirements.txt -q

echo -e "${GREEN}✓ Python environment ready${NC}"

# Generate secret key
echo -e "${YELLOW}[6/8] Generating configuration...${NC}"

SECRET_KEY=$(python3 -c "import secrets; print(secrets.token_hex(32))")

# Create .env file
cat > $APP_DIR/.env << EOF
# Generated automatically by setup-server.sh
SECRET_KEY=$SECRET_KEY
ACCESS_TOKEN_EXPIRE_MINUTES=60
BACKEND_CORS_ORIGINS=http://localhost:3000
DATABASE_URL=postgresql+psycopg://$DB_USER:$DB_PASSWORD@localhost:5432/$DB_NAME
ENVIRONMENT=prod

# Optional: Add these manually if needed
GOOGLE_CLIENT_ID=
TELEGRAM_BOT_TOKEN=
TELEGRAM_AUTH_MAX_AGE=300
EOF

chmod 600 $APP_DIR/.env

echo -e "${GREEN}✓ Configuration file created${NC}"
echo -e "${YELLOW}   Database credentials saved to .env${NC}"

# Create systemd service
echo -e "${YELLOW}[7/8] Creating systemd service...${NC}"

sudo tee /etc/systemd/system/closefriend.service > /dev/null << EOF
[Unit]
Description=CloseFriend FastAPI Application
After=network.target postgresql.service
Requires=postgresql.service

[Service]
Type=notify
User=$USER
Group=$USER
WorkingDirectory=$APP_DIR
Environment="PATH=$APP_DIR/.venv/bin"
EnvironmentFile=$APP_DIR/.env
ExecStart=$APP_DIR/.venv/bin/gunicorn app.main:app \\
    --workers 4 \\
    --worker-class uvicorn.workers.UvicornWorker \\
    --bind 127.0.0.1:8000 \\
    --access-logfile /var/log/closefriend/access.log \\
    --error-logfile /var/log/closefriend/error.log \\
    --log-level info
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Create log directory
sudo mkdir -p /var/log/closefriend
sudo chown $USER:$USER /var/log/closefriend

# Reload systemd
sudo systemctl daemon-reload
sudo systemctl enable closefriend
sudo systemctl start closefriend

echo -e "${GREEN}✓ Systemd service created and started${NC}"

# Configure Nginx
echo -e "${YELLOW}[8/8] Configuring Nginx...${NC}"

# Get server IP or hostname
SERVER_IP=$(curl -s ifconfig.me || echo "your-server-ip")
read -p "Enter your domain name (or press Enter to use IP: $SERVER_IP): " DOMAIN
DOMAIN=${DOMAIN:-$SERVER_IP}

sudo tee /etc/nginx/sites-available/closefriend > /dev/null << EOF
server {
    listen 80;
    server_name $DOMAIN;
    client_max_body_size 10M;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # WebSocket support (if needed)
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
    }

    location /static {
        alias $APP_DIR/static;
        expires 30d;
    }
}
EOF

# Enable site
sudo ln -sf /etc/nginx/sites-available/closefriend /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Test nginx config
sudo nginx -t

# Restart nginx
sudo systemctl restart nginx
sudo systemctl enable nginx

echo -e "${GREEN}✓ Nginx configured${NC}"

# Configure firewall
echo -e "${YELLOW}Configuring firewall...${NC}"
sudo ufw --force enable
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw reload

echo -e "${GREEN}✓ Firewall configured${NC}"

# Setup SSL (optional)
echo ""
read -p "Do you want to setup SSL with Let's Encrypt? (y/n): " SETUP_SSL
if [ "$SETUP_SSL" = "y" ] || [ "$SETUP_SSL" = "Y" ]; then
    if [ "$DOMAIN" != "$SERVER_IP" ]; then
        echo -e "${YELLOW}Setting up SSL...${NC}"
        sudo certbot --nginx -d $DOMAIN --non-interactive --agree-tos --email admin@$DOMAIN || {
            echo -e "${YELLOW}⚠️  SSL setup failed. You can run it manually later:${NC}"
            echo -e "${YELLOW}   sudo certbot --nginx -d $DOMAIN${NC}"
        }
    else
        echo -e "${YELLOW}⚠️  Cannot setup SSL for IP address. Use a domain name.${NC}"
    fi
fi

# Check service status
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                  Setup Complete! ✓                          ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}📊 Service Status:${NC}"
sudo systemctl status closefriend --no-pager -l | head -10
echo ""

echo -e "${GREEN}🔍 Quick Check:${NC}"
sleep 2
curl -s http://localhost:8000/openapi.json > /dev/null && echo -e "${GREEN}✓ API is responding${NC}" || echo -e "${RED}✗ API not responding${NC}"

echo ""
echo -e "${GREEN}🌐 Your API is now available at:${NC}"
echo -e "   ${YELLOW}http://$DOMAIN${NC}"
echo -e "   ${YELLOW}http://$DOMAIN/swagger${NC} (API Documentation)"
echo -e "   ${YELLOW}http://$DOMAIN/redoc${NC} (API Documentation)"
echo ""

echo -e "${GREEN}📝 Important Information:${NC}"
echo -e "   App Directory: ${YELLOW}$APP_DIR${NC}"
echo -e "   Database Name: ${YELLOW}$DB_NAME${NC}"
echo -e "   Database User: ${YELLOW}$DB_USER${NC}"
echo -e "   Database Password: ${YELLOW}$DB_PASSWORD${NC}"
echo -e "   Config File: ${YELLOW}$APP_DIR/.env${NC}"
echo -e "   Logs: ${YELLOW}/var/log/closefriend/${NC}"
echo ""

echo -e "${GREEN}🔧 Useful Commands:${NC}"
echo -e "   ${YELLOW}sudo systemctl status closefriend${NC}   - Check service status"
echo -e "   ${YELLOW}sudo systemctl restart closefriend${NC}  - Restart service"
echo -e "   ${YELLOW}sudo systemctl stop closefriend${NC}     - Stop service"
echo -e "   ${YELLOW}sudo journalctl -u closefriend -f${NC}   - View live logs"
echo -e "   ${YELLOW}sudo tail -f /var/log/closefriend/error.log${NC} - View error logs"
echo ""

echo -e "${GREEN}⚙️  Configuration:${NC}"
echo -e "   To update CORS origins, Google Client ID, or Telegram token:"
echo -e "   ${YELLOW}nano $APP_DIR/.env${NC}"
echo -e "   ${YELLOW}sudo systemctl restart closefriend${NC}"
echo ""

# Save credentials to a secure file
CRED_FILE="$APP_DIR/.credentials"
cat > $CRED_FILE << EOF
CloseFriend Setup Credentials
==============================
Date: $(date)

Database Name: $DB_NAME
Database User: $DB_USER
Database Password: $DB_PASSWORD
Database URL: postgresql+psycopg://$DB_USER:$DB_PASSWORD@localhost:5432/$DB_NAME

Secret Key: $SECRET_KEY

Domain: $DOMAIN
API URL: http://$DOMAIN
Swagger UI: http://$DOMAIN/swagger

Application Directory: $APP_DIR
EOF

chmod 600 $CRED_FILE
echo -e "${YELLOW}💾 Credentials saved to: $CRED_FILE${NC}"
echo ""

echo -e "${GREEN}✨ Setup completed successfully!${NC}"
