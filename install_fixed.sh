#!/bin/bash
# Fixed installation script for Stand Up Sydney FastMCP Server

set -e

echo "🔧 Installing Stand Up Sydney FastMCP Server (Fixed Version)"

# Configuration
MCP_DIR="/opt/standup-sydney-mcp"
SERVICE_NAME="standup-sydney-fastmcp"
USER="root"

# Create directory structure
echo "📁 Creating directory structure..."
mkdir -p "$MCP_DIR/logs"
mkdir -p "$MCP_DIR/backups"

# Copy files
echo "📋 Copying server files..."
cp server_fixed.py "$MCP_DIR/server.py"
cp requirements.txt "$MCP_DIR/"

# Create .env template if it doesn't exist
if [ ! -f "$MCP_DIR/.env" ]; then
    echo "📝 Creating .env template..."
    cat > "$MCP_DIR/.env" << EOF
# Stand Up Sydney FastMCP Server Environment Variables
# Copy this template and fill in your actual values

# Server Configuration
HOST=0.0.0.0
PORT=8080

# Supabase Configuration
SUPABASE_URL=your_supabase_url_here
SUPABASE_ANON_KEY=your_supabase_anon_key_here

# GitHub Integration (Optional)
GITHUB_TOKEN=your_github_token_here

# Notion Integration (Optional)  
NOTION_TOKEN=your_notion_token_here

# Metricool Integration (Optional)
METRICOOL_API_KEY=your_metricool_api_key_here
EOF
    echo "⚠️  Please edit $MCP_DIR/.env with your actual API keys"
fi

# Set up Python virtual environment
echo "🐍 Setting up Python virtual environment..."
cd "$MCP_DIR"

# Remove old venv if it exists
if [ -d "venv" ]; then
    echo "Removing old virtual environment..."
    rm -rf venv
fi

# Create new virtual environment
python3 -m venv venv
source venv/bin/activate

# Upgrade pip
pip install --upgrade pip

# Install dependencies with error handling
echo "📦 Installing Python dependencies..."
pip install fastmcp>=0.3.0 || {
    echo "❌ Failed to install fastmcp"
    echo "Trying alternative installation..."
    pip install git+https://github.com/jlowin/fastmcp.git || {
        echo "❌ FastMCP installation failed completely"
        echo "Please install manually: pip install fastmcp"
    }
}

# Install other dependencies
pip install python-dotenv>=1.0.0
pip install uvicorn>=0.24.0
pip install pydantic>=2.0.0
pip install requests>=2.31.0

# Optional dependencies (install if API keys are available)
pip install supabase>=2.0.0 || echo "⚠️ Supabase client failed to install"
pip install pygithub>=2.0.0 || echo "⚠️ PyGithub failed to install"
pip install notion-client>=2.0.0 || echo "⚠️ Notion client failed to install"

echo "✅ Dependencies installed"

# Test the server
echo "🧪 Testing server startup..."
timeout 10s python server.py &
SERVER_PID=$!
sleep 3

if kill -0 $SERVER_PID 2>/dev/null; then
    echo "✅ Server started successfully"
    kill $SERVER_PID
else
    echo "❌ Server failed to start - checking logs..."
    cat logs/fastmcp.log 2>/dev/null || echo "No log file found"
fi

# Create systemd service
echo "⚙️ Creating systemd service..."
cat > /etc/systemd/system/$SERVICE_NAME.service << EOF
[Unit]
Description=Stand Up Sydney FastMCP Server
After=network.target
Wants=network.target

[Service]
Type=simple
User=$USER
Group=$USER
WorkingDirectory=$MCP_DIR
Environment=PATH=$MCP_DIR/venv/bin
ExecStart=$MCP_DIR/venv/bin/python server.py
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=$SERVICE_NAME

# Resource limits
MemoryLimit=512M
CPUQuota=50%

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=$MCP_DIR

[Install]
WantedBy=multi-user.target
EOF

# Set permissions
echo "🔒 Setting permissions..."
chown -R $USER:$USER "$MCP_DIR"
chmod +x "$MCP_DIR/server.py"
chmod 600 "$MCP_DIR/.env"

# Reload systemd and enable service
echo "🔄 Configuring systemd service..."
systemctl daemon-reload
systemctl enable $SERVICE_NAME

# Check if service exists and show status
if systemctl list-unit-files | grep -q "$SERVICE_NAME"; then
    echo "✅ Service created successfully"
    
    echo "🚀 Starting service..."
    systemctl start $SERVICE_NAME
    
    # Check service status
    sleep 3
    if systemctl is-active --quiet $SERVICE_NAME; then
        echo "✅ Service is running!"
        systemctl status $SERVICE_NAME --no-pager -l
    else
        echo "❌ Service failed to start"
        echo "Checking logs..."
        journalctl -u $SERVICE_NAME --no-pager -l --since "1 minute ago"
    fi
else
    echo "❌ Failed to create systemd service"
fi

echo ""
echo "🎯 Installation Summary:"
echo "   Server directory: $MCP_DIR"
echo "   Service name: $SERVICE_NAME"
echo "   Log files: $MCP_DIR/logs/"
echo "   Environment: $MCP_DIR/.env"
echo ""
echo "📋 Useful Commands:"
echo "   Check status: systemctl status $SERVICE_NAME"
echo "   View logs: journalctl -u $SERVICE_NAME -f"
echo "   Restart: systemctl restart $SERVICE_NAME"
echo "   Test manually: cd $MCP_DIR && source venv/bin/activate && python server.py"
echo ""
echo "⚠️  Remember to edit $MCP_DIR/.env with your actual API keys!"