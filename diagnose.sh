#!/bin/bash
# FastMCP Server Diagnostic Script

echo "🔍 Stand Up Sydney FastMCP Server Diagnostics"
echo "============================================="

MCP_DIR="/opt/standup-sydney-mcp"
SERVICE_NAME="standup-sydney-fastmcp"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "⚠️  Running as non-root user. Some checks may fail."
fi

echo ""
echo "📁 Directory Structure:"
echo "----------------------"
if [ -d "$MCP_DIR" ]; then
    echo "✅ MCP directory exists: $MCP_DIR"
    ls -la "$MCP_DIR"
    
    echo ""
    echo "📁 Subdirectories:"
    for dir in logs backups venv; do
        if [ -d "$MCP_DIR/$dir" ]; then
            echo "✅ $dir/ exists"
        else
            echo "❌ $dir/ missing"
        fi
    done
else
    echo "❌ MCP directory missing: $MCP_DIR"
fi

echo ""
echo "📋 Files Check:"
echo "---------------"
for file in server.py requirements.txt .env; do
    if [ -f "$MCP_DIR/$file" ]; then
        echo "✅ $file exists"
        if [ "$file" = "server.py" ]; then
            # Check if it's the fixed version
            if grep -q "Fixed version" "$MCP_DIR/$file"; then
                echo "   ✅ Using fixed version"
            else
                echo "   ⚠️  Using original version (may have issues)"
            fi
        fi
    else
        echo "❌ $file missing"
    fi
done

echo ""
echo "🐍 Python Environment:"
echo "----------------------"
if [ -f "$MCP_DIR/venv/bin/python" ]; then
    echo "✅ Virtual environment exists"
    echo "Python version: $($MCP_DIR/venv/bin/python --version)"
    
    echo ""
    echo "📦 Installed packages:"
    $MCP_DIR/venv/bin/pip list | grep -E "(fastmcp|supabase|github|notion|uvicorn|pydantic)"
    
    echo ""
    echo "🧪 Testing FastMCP import:"
    if $MCP_DIR/venv/bin/python -c "from fastmcp import FastMCP; print('✅ FastMCP import successful')" 2>/dev/null; then
        echo "✅ FastMCP can be imported"
    else
        echo "❌ FastMCP import failed"
        echo "Error details:"
        $MCP_DIR/venv/bin/python -c "from fastmcp import FastMCP" 2>&1 || true
    fi
else
    echo "❌ Virtual environment missing"
fi

echo ""
echo "🔧 Environment Variables:"
echo "-------------------------"
if [ -f "$MCP_DIR/.env" ]; then
    echo "✅ .env file exists"
    echo "Variables set:"
    grep -E "^[A-Z_]+=" "$MCP_DIR/.env" | sed 's/=.*/=***/' | head -10
    
    # Check for required variables
    for var in SUPABASE_URL SUPABASE_ANON_KEY; do
        if grep -q "^$var=" "$MCP_DIR/.env" && ! grep -q "^$var=your_" "$MCP_DIR/.env"; then
            echo "✅ $var is configured"
        else
            echo "⚠️  $var needs to be set"
        fi
    done
else
    echo "❌ .env file missing"
fi

echo ""
echo "⚙️ Systemd Service:"
echo "-------------------"
if systemctl list-unit-files | grep -q "$SERVICE_NAME"; then
    echo "✅ Service exists: $SERVICE_NAME"
    
    # Service status
    if systemctl is-active --quiet $SERVICE_NAME; then
        echo "✅ Service is running"
    else
        echo "❌ Service is not running"
    fi
    
    if systemctl is-enabled --quiet $SERVICE_NAME; then
        echo "✅ Service is enabled (will start on boot)"
    else
        echo "⚠️  Service is not enabled"
    fi
    
    echo ""
    echo "📊 Service Status:"
    systemctl status $SERVICE_NAME --no-pager -l | head -20
    
else
    echo "❌ Service does not exist: $SERVICE_NAME"
fi

echo ""
echo "📜 Recent Logs:"
echo "---------------"
if [ -f "$MCP_DIR/logs/fastmcp.log" ]; then
    echo "✅ Log file exists"
    echo "Last 10 lines:"
    tail -10 "$MCP_DIR/logs/fastmcp.log"
else
    echo "⚠️  No log file found"
fi

echo ""
echo "📜 Systemd Journal (last 20 lines):"
journalctl -u $SERVICE_NAME --no-pager -l --since "10 minutes ago" | tail -20

echo ""
echo "🌐 Network Check:"
echo "-----------------"
echo "Checking port 8080..."
if netstat -tlnp | grep -q ":8080"; then
    echo "✅ Port 8080 is in use"
    netstat -tlnp | grep ":8080"
else
    echo "❌ Port 8080 is not in use"
fi

echo ""
echo "🔥 Firewall Check:"
echo "------------------"
if command -v ufw &> /dev/null; then
    echo "UFW status:"
    ufw status | grep -E "(8080|Status)"
else
    echo "UFW not installed"
fi

echo ""
echo "💾 Disk Space:"
echo "--------------"
df -h "$MCP_DIR" 2>/dev/null || df -h /

echo ""
echo "🧠 Memory Usage:"
echo "----------------"
free -h

echo ""
echo "🔄 Quick Fixes:"
echo "---------------"
echo "To restart the service: systemctl restart $SERVICE_NAME"
echo "To view live logs: journalctl -u $SERVICE_NAME -f"
echo "To test manually: cd $MCP_DIR && source venv/bin/activate && python server.py"
echo "To reinstall: ./install_fixed.sh"
echo ""

# Offer to run a quick test
echo "🧪 Would you like to run a quick manual test? (y/n)"
read -r response
if [[ "$response" =~ ^[Yy]$ ]]; then
    echo "Running quick test..."
    cd "$MCP_DIR" || exit 1
    source venv/bin/activate
    timeout 10s python server.py &
    sleep 3
    if curl -s http://localhost:8080/health >/dev/null 2>&1; then
        echo "✅ Server responds to HTTP requests"
    else
        echo "❌ Server not responding on port 8080"
    fi
    pkill -f "python server.py" 2>/dev/null || true
fi

echo ""
echo "🎯 Diagnostics complete!"