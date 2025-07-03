# 🚀 Stand Up Sydney FastMCP Deployment Guide

## 🏗️ Architecture Overview

**CRITICAL: FastMCP runs DIRECTLY on the DigitalOcean droplet, NOT as a DigitalOcean App**

```
┌─────────────────────────────────────────┐
│ DigitalOcean Droplet: 170.64.252.55    │
│ 4 vCPU / 8GB RAM / Sydney Region       │
├─────────────────────────────────────────┤
│ FastMCP Server (Port 8080)              │
│ ├── Supabase MCP                        │
│ ├── GitHub MCP                          │
│ ├── Notion MCP                          │
│ ├── Metricool MCP                       │
│ ├── Browser MCP                         │
│ └── Filesystem MCP                      │
└─────────────────────────────────────────┘
              │
              ▼
    Claude Desktop/Web Connection
```

## ⚠️ IMPORTANT: No DigitalOcean Apps!

- **DO NOT** create DigitalOcean Apps for FastMCP
- **DO NOT** use App Platform for MCP hosting
- **ONLY** deploy directly to the droplet at 170.64.252.55

## 🛠️ Deployment Process

### 1. Server Setup
```bash
ssh root@170.64.252.55
cd /opt/standup-sydney-mcp
python3 -m venv venv
source venv/bin/activate
pip install fastmcp supabase-py pygithub notion-client
```

### 2. FastMCP Configuration
```bash
# Clone/update repository
git clone https://github.com/chillz-id/standup-sydney-mcp-tools.git
cd standup-sydney-mcp-tools

# Set environment variables
export SUPABASE_URL="your_supabase_url"
export SUPABASE_ANON_KEY="your_supabase_key" 
export GITHUB_TOKEN="your_github_token"
export NOTION_TOKEN="your_notion_token"
export METRICOOL_API_KEY="your_metricool_key"

# Run FastMCP server
python3 server.py
```

### 3. Systemd Service (Production)
```bash
sudo systemctl enable standup-sydney-fastmcp
sudo systemctl start standup-sydney-fastmcp
sudo systemctl status standup-sydney-fastmcp
```

## 🔌 Claude Connection

### Claude Desktop
```json
{
  "mcpServers": {
    "standup-sydney": {
      "command": "curl",
      "args": ["-X", "POST", "http://170.64.252.55:8080/mcp"],
      "env": {}
    }
  }
}
```

### Claude Web (via MCP Gateway)
- Endpoint: `http://170.64.252.55:8080`
- Protocol: HTTP (internal network)
- Authentication: API key based

## 📊 Monitoring & Health

- **Health Check**: `http://170.64.252.55:8080/health`
- **Tools List**: `http://170.64.252.55:8080/tools`
- **Logs**: `/var/log/standup-sydney-fastmcp.log`

---

**Last Updated**: July 3, 2025  
**Deployment Target**: DigitalOcean Droplet (170.64.252.55)  
**Architecture**: Single FastMCP server with consolidated MCP tools
