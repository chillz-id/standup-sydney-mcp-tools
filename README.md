# 🚀 Stand Up Sydney MCP Business Tools

**Production-ready MCP (Model Context Protocol) server deployment for Stand Up Sydney comedy platform**

This repository contains Docker-based MCP business tools that enable Claude AI to interact with various business services like Notion, GitHub, Metricool, and more.

## 🎯 Quick Start

**One-line installation on Digital Ocean droplet (170.64.252.55):**

```bash
curl -sSL https://raw.githubusercontent.com/chillz-id/standup-sydney-mcp-tools/main/deploy.sh | bash
```

## 🏗️ Architecture

```
Digital Ocean Droplet (170.64.252.55)
├── Notion MCP Server       :3001
├── GitHub MCP Server       :3002  
├── Filesystem MCP Server   :3003
├── Metricool MCP Server    :3004
├── Google Drive MCP Server :3005
└── MCP Gateway             :8000
```

## 📋 Services Included

| Service | Port | Description | Status |
|---------|------|-------------|--------|
| **Notion** | 3001 | Project management & knowledge base | ✅ Ready |
| **GitHub** | 3002 | Repository management & CI/CD | ✅ Ready |
| **Filesystem** | 3003 | Local file operations | ✅ Ready |
| **Metricool** | 3004 | Social media analytics & scheduling | ✅ Ready |
| **Google Drive** | 3005 | Document management & sharing | ✅ Ready |
| **Gateway** | 8000 | Unified API proxy for all services | ✅ Ready |

## 🛠️ Manual Installation

### Prerequisites

- Ubuntu 20.04+ server
- Docker & Docker Compose
- 4GB+ RAM recommended
- Ports 3001-3005, 8000 open

### Step 1: Clone Repository

```bash
git clone https://github.com/chillz-id/standup-sydney-mcp-tools.git
cd standup-sydney-mcp-tools
```

### Step 2: Configure Environment

```bash
# Copy template and edit with your API keys
cp .env.template .env
nano .env
```

**Required API Keys:**

- **Notion**: [Get integration token](https://developers.notion.com/docs/create-a-notion-integration)
- **GitHub**: [Generate personal access token](https://github.com/settings/tokens)
- **Metricool**: [Get API credentials](https://metricool.com/api/)

### Step 3: Deploy Services

```bash
# Start all MCP services
docker compose up -d

# Check status
docker compose ps

# View logs
docker compose logs -f
```

## 🔌 Claude Integration

### For Claude Desktop

Add to your Claude Desktop MCP configuration:

```json
{
  "mcpServers": {
    "standup-sydney-gateway": {
      "command": "node",
      "args": ["/path/to/mcp-client.js"],
      "env": {
        "MCP_SERVER_URL": "http://170.64.252.55:8000"
      }
    }
  }
}
```

### For Claude Code

```bash
export MCP_SERVER_URL=http://170.64.252.55:8000
export MCP_TRANSPORT=sse
```

## 🧪 Testing Installation

### Health Checks

```bash
# Test gateway
curl http://170.64.252.55:8000/health

# Test individual services
curl http://170.64.252.55:3001/health  # Notion
curl http://170.64.252.55:3002/health  # GitHub
curl http://170.64.252.55:3003/health  # Filesystem
curl http://170.64.252.55:3004/health  # Metricool
```

### Service Discovery

```bash
# List all available services
curl http://170.64.252.55:8000/services
```

## 📊 Monitoring & Logs

### View Service Status

```bash
cd /opt/standup-sydney-mcp
docker compose ps
```

### Check Logs

```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f notion-mcp
docker compose logs -f github-mcp
docker compose logs -f metricool-mcp
```

## 🔧 Maintenance

### Update Services

```bash
cd /opt/standup-sydney-mcp
docker compose pull
docker compose up -d
```

### Restart Services

```bash
# Restart all
docker compose restart

# Restart specific service
docker compose restart notion-mcp
```

## 🚨 Troubleshooting

### Common Issues

**Port Already in Use:**
```bash
sudo netstat -tulpn | grep :3001
sudo fuser -k 3001/tcp
```

**Permission Denied:**
```bash
sudo chown -R $USER:$USER /opt/standup-sydney-mcp
```

**API Key Issues:**
```bash
# Verify environment variables
docker compose exec notion-mcp printenv | grep NOTION
```

## 🔐 Security

- All API keys stored in environment variables
- No sensitive data in Docker images
- Firewall configured for specific ports only
- Regular security updates via automated deployment

---

**🎭 Built for Stand Up Sydney** | **🤖 Powered by Claude MCP** | **☁️ Deployed on Digital Ocean**