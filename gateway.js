const express = require('express');
const { createProxyMiddleware } = require('http-proxy-middleware');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 8000;

// Enable CORS for all routes
app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With']
}));

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ 
    status: 'healthy', 
    timestamp: new Date().toISOString(),
    services: {
      notion: process.env.NOTION_MCP_URL || 'http://notion-mcp:3000',
      github: process.env.GITHUB_MCP_URL || 'http://github-mcp:3000',
      filesystem: process.env.FILESYSTEM_MCP_URL || 'http://filesystem-mcp:3000',
      metricool: process.env.METRICOOL_MCP_URL || 'http://metricool-mcp:3000',
      gdrive: process.env.GDRIVE_MCP_URL || 'http://gdrive-mcp:3000'
    }
  });
});

// Service discovery endpoint
app.get('/services', (req, res) => {
  res.json({
    services: [
      { name: 'notion', url: '/notion', description: 'Notion MCP Server' },
      { name: 'github', url: '/github', description: 'GitHub MCP Server' },
      { name: 'filesystem', url: '/filesystem', description: 'Filesystem MCP Server' },
      { name: 'metricool', url: '/metricool', description: 'Metricool MCP Server' },
      { name: 'gdrive', url: '/gdrive', description: 'Google Drive MCP Server' }
    ]
  });
});

// Proxy configurations for each MCP service
const proxyOptions = {
  changeOrigin: true,
  ws: true, // Enable WebSocket proxying
  timeout: 30000,
  proxyTimeout: 30000,
  onError: (err, req, res) => {
    console.error('Proxy error:', err);
    res.status(500).json({ error: 'Service temporarily unavailable' });
  }
};

// Notion MCP Proxy
app.use('/notion', createProxyMiddleware({
  ...proxyOptions,
  target: process.env.NOTION_MCP_URL || 'http://notion-mcp:3000',
  pathRewrite: { '^/notion': '' }
}));

// GitHub MCP Proxy
app.use('/github', createProxyMiddleware({
  ...proxyOptions,
  target: process.env.GITHUB_MCP_URL || 'http://github-mcp:3000',
  pathRewrite: { '^/github': '' }
}));

// Filesystem MCP Proxy
app.use('/filesystem', createProxyMiddleware({
  ...proxyOptions,
  target: process.env.FILESYSTEM_MCP_URL || 'http://filesystem-mcp:3000',
  pathRewrite: { '^/filesystem': '' }
}));

// Metricool MCP Proxy
app.use('/metricool', createProxyMiddleware({
  ...proxyOptions,
  target: process.env.METRICOOL_MCP_URL || 'http://metricool-mcp:3000',
  pathRewrite: { '^/metricool': '' }
}));

// Google Drive MCP Proxy
app.use('/gdrive', createProxyMiddleware({
  ...proxyOptions,
  target: process.env.GDRIVE_MCP_URL || 'http://gdrive-mcp:3000',
  pathRewrite: { '^/gdrive': '' }
}));

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({ 
    error: 'Service not found',
    available_services: ['/notion', '/github', '/filesystem', '/metricool', '/gdrive'],
    help: 'Visit /services for service discovery'
  });
});

// Start server
app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 MCP Gateway Server running on port ${PORT}`);
  console.log(`📊 Health check: http://localhost:${PORT}/health`);
  console.log(`📋 Services: http://localhost:${PORT}/services`);
  console.log(`🔗 Available routes:`);
  console.log(`   • Notion: http://localhost:${PORT}/notion`);
  console.log(`   • GitHub: http://localhost:${PORT}/github`);
  console.log(`   • Filesystem: http://localhost:${PORT}/filesystem`);
  console.log(`   • Metricool: http://localhost:${PORT}/metricool`);
  console.log(`   • Google Drive: http://localhost:${PORT}/gdrive`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('🛑 MCP Gateway shutting down gracefully...');
  process.exit(0);
});

process.on('SIGINT', () => {
  console.log('🛑 MCP Gateway shutting down gracefully...');
  process.exit(0);
});