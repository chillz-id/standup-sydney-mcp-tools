#!/bin/bash
# Stand Up Sydney MCP Quick Deploy Script
# For Digital Ocean droplet at 170.64.252.55
# Usage: curl -sSL https://raw.githubusercontent.com/chillz-id/standup-sydney-mcp-tools/main/deploy.sh | bash

set -e

echo "🚀 Stand Up Sydney MCP Business Tools Quick Deploy"
echo "=================================================="

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[$(date '+%H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date '+%H:%M:%S')] $1${NC}"
}

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    log "Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
    
    # Install Docker Compose
    sudo apt update
    sudo apt install -y docker-compose-plugin
    
    warn "Docker installed. You may need to log out and back in for group changes to take effect."
    warn "Re-run this script after logging back in."
    exit 0
fi

# Create project directory
PROJECT_DIR="/opt/standup-sydney-mcp"
log "Creating project directory: $PROJECT_DIR"
sudo mkdir -p $PROJECT_DIR
sudo chown $USER:$USER $PROJECT_DIR
cd $PROJECT_DIR

# Download configuration files from GitHub
log "Downloading configuration files..."
curl -sSL https://raw.githubusercontent.com/chillz-id/standup-sydney-mcp-tools/main/docker-compose.yml -o docker-compose.yml
curl -sSL https://raw.githubusercontent.com/chillz-id/standup-sydney-mcp-tools/main/gateway.js -o gateway.js
curl -sSL https://raw.githubusercontent.com/chillz-id/standup-sydney-mcp-tools/main/.env.template -o .env.template

# Create default .env file if it doesn't exist
if [ ! -f .env ]; then
    log "Creating default environment file..."
    cp .env.template .env
fi

# Configure firewall
log "Configuring firewall for MCP ports..."
sudo ufw allow 3001/tcp comment 'Notion MCP' 2>/dev/null || true
sudo ufw allow 3002/tcp comment 'GitHub MCP' 2>/dev/null || true
sudo ufw allow 3003/tcp comment 'Filesystem MCP' 2>/dev/null || true
sudo ufw allow 3004/tcp comment 'Metricool MCP' 2>/dev/null || true
sudo ufw allow 3005/tcp comment 'Google Drive MCP' 2>/dev/null || true
sudo ufw allow 8000/tcp comment 'MCP Gateway' 2>/dev/null || true

# Pull Docker images
log "Pulling Docker images..."
docker compose pull

# Create systemd service for auto-start
log "Creating systemd service..."
sudo tee /etc/systemd/system/standup-sydney-mcp.service > /dev/null << EOF
[Unit]
Description=Stand Up Sydney MCP Business Tools
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=$PROJECT_DIR
ExecStart=/usr/bin/docker compose up -d
ExecStop=/usr/bin/docker compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable standup-sydney-mcp.service

echo ""
echo "✅ MCP Business Tools setup complete!"
echo ""
echo "📋 Next steps:"
echo "1. Edit $PROJECT_DIR/.env with your API keys:"
echo "   - NOTION_API_KEY"
echo "   - GITHUB_PERSONAL_ACCESS_TOKEN"
echo "   - METRICOOL_USER_TOKEN"
echo "   - METRICOOL_USER_ID"
echo ""
echo "2. Start the services:"
echo "   cd $PROJECT_DIR"
echo "   docker compose up -d"
echo ""
echo "3. Check service status:"
echo "   docker compose ps"
echo "   docker compose logs -f"
echo ""
echo "🔗 Service URLs (after starting):"
echo "   • Notion MCP: http://170.64.252.55:3001"
echo "   • GitHub MCP: http://170.64.252.55:3002"
echo "   • Filesystem MCP: http://170.64.252.55:3003"
echo "   • Metricool MCP: http://170.64.252.55:3004"
echo "   • Google Drive MCP: http://170.64.252.55:3005"
echo "   • MCP Gateway: http://170.64.252.55:8000"
echo ""
echo "🎯 Test gateway health: curl http://170.64.252.55:8000/health"