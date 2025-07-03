#!/bin/bash
#
# Stand Up Sydney FastMCP Deployment Script
# Deploy FastMCP server directly to DigitalOcean droplet 170.64.252.55
#
# Usage: ./deploy.sh
#

set -e

echo "🚀 Deploying Stand Up Sydney FastMCP Server to Droplet"
echo "Target: 170.64.252.55 (Sydney region)"
echo

# Configuration
APP_DIR="/opt/standup-sydney-mcp"
APP_USER="fastmcp"
SERVICE_NAME="standup-sydney-fastmcp"
REPO_URL="https://github.com/chillz-id/standup-sydney-mcp-tools.git"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   print_error "This script must be run as root (use sudo)"
   exit 1
fi

print_status "Step 1: Installing system dependencies..."
apt update
apt install -y python3 python3-pip python3-venv git curl

print_status "Step 2: Creating application user and directory..."
if ! id "$APP_USER" &>/dev/null; then
    useradd --system --home-dir $APP_DIR --shell /bin/bash $APP_USER
    print_status "Created user: $APP_USER"
else
    print_warning "User $APP_USER already exists"
fi

# Create application directory
mkdir -p $APP_DIR
cd $APP_DIR

print_status "Step 3: Cloning/updating repository..."
if [ -d ".git" ]; then
    print_status "Repository exists, pulling latest changes..."
    sudo -u $APP_USER git pull
else
    print_status "Cloning repository..."
    sudo -u $APP_USER git clone $REPO_URL .
fi

print_status "Step 4: Setting up Python virtual environment..."
sudo -u $APP_USER python3 -m venv venv
sudo -u $APP_USER ./venv/bin/pip install --upgrade pip
sudo -u $APP_USER ./venv/bin/pip install -r requirements.txt

print_status "Step 5: Creating environment file..."
cat > $APP_DIR/.env << EOF
# Stand Up Sydney FastMCP Environment Configuration
# Update these values with your actual credentials

HOST=0.0.0.0
PORT=8080

# Supabase Configuration
SUPABASE_URL=your_supabase_url_here
SUPABASE_ANON_KEY=your_supabase_anon_key_here

# GitHub Configuration
GITHUB_TOKEN=your_github_token_here

# Notion Configuration
NOTION_TOKEN=your_notion_token_here

# Metricool Configuration
METRICOOL_API_KEY=your_metricool_api_key_here

# Logging
LOG_LEVEL=INFO
EOF

chown $APP_USER:$APP_USER $APP_DIR/.env
chmod 600 $APP_DIR/.env

print_warning "⚠️  IMPORTANT: Edit $APP_DIR/.env with your actual API credentials!"

print_status "Step 6: Creating systemd service..."
cat > /etc/systemd/system/$SERVICE_NAME.service << EOF
[Unit]
Description=Stand Up Sydney FastMCP Server
After=network.target
Wants=network.target

[Service]
Type=simple
User=$APP_USER
Group=$APP_USER
WorkingDirectory=$APP_DIR
Environment=PATH=$APP_DIR/venv/bin
EnvironmentFile=$APP_DIR/.env
ExecStart=$APP_DIR/venv/bin/python server.py
Restart=always
RestartSec=10

# Security settings
NoNewPrivileges=yes
ProtectSystem=strict
ProtectHome=yes
ReadWritePaths=$APP_DIR /var/log

# Logging
StandardOutput=journal
StandardError=journal
SyslogIdentifier=$SERVICE_NAME

[Install]
WantedBy=multi-user.target
EOF

print_status "Step 7: Enabling and starting service..."
systemctl daemon-reload
systemctl enable $SERVICE_NAME

print_status "Step 8: Setting up log directory..."
mkdir -p /var/log
touch /var/log/standup-sydney-fastmcp.log
chown $APP_USER:$APP_USER /var/log/standup-sydney-fastmcp.log

print_status "Step 9: Setting up firewall..."
ufw allow 8080/tcp
print_status "Opened port 8080 for FastMCP server"

print_status "Step 10: Setting permissions..."
chown -R $APP_USER:$APP_USER $APP_DIR

echo
print_status "✅ FastMCP Server Deployment Complete!"
echo
echo "📋 Next Steps:"
echo "1. Edit environment file: sudo nano $APP_DIR/.env"
echo "2. Add your API credentials (Supabase, GitHub, Notion, Metricool)"
echo "3. Start the service: sudo systemctl start $SERVICE_NAME"
echo "4. Check status: sudo systemctl status $SERVICE_NAME"
echo "5. View logs: sudo journalctl -u $SERVICE_NAME -f"
echo
echo "🔗 Endpoints:"
echo "  Health Check: http://170.64.252.55:8080/health"
echo "  Tools List: http://170.64.252.55:8080/tools"
echo
echo "📖 Full documentation: $APP_DIR/DEPLOYMENT.md"
echo

print_warning "Remember: NO DigitalOcean Apps! This runs directly on the droplet."