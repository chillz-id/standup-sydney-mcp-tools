#!/usr/bin/env python3
"""
FastMCP Server for Stand Up Sydney Platform
Fixed version with proper error handling and logging
"""

import os
import json
import logging
import sys
from typing import Dict, Any, List, Optional
from datetime import datetime
import asyncio
from pathlib import Path

# Create logs directory if it doesn't exist
log_dir = Path("/opt/standup-sydney-mcp/logs")
log_dir.mkdir(exist_ok=True)

# Configure logging with fallback
try:
    log_file = log_dir / "fastmcp.log"
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
        handlers=[
            logging.FileHandler(str(log_file)),
            logging.StreamHandler()
        ]
    )
except PermissionError:
    # Fallback to stdout only if log file can't be created
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
        handlers=[logging.StreamHandler()]
    )

logger = logging.getLogger(__name__)

# Try to import FastMCP with error handling
try:
    from fastmcp import FastMCP
    logger.info("FastMCP imported successfully")
except ImportError as e:
    logger.error(f"Failed to import FastMCP: {e}")
    logger.error("Please install fastmcp: pip install fastmcp>=0.3.0")
    sys.exit(1)

# Load environment variables from .env file if it exists
try:
    from dotenv import load_dotenv
    env_file = Path("/opt/standup-sydney-mcp/.env")
    if env_file.exists():
        load_dotenv(env_file)
        logger.info("Loaded environment variables from .env file")
except ImportError:
    logger.warning("python-dotenv not installed, skipping .env file loading")

# Initialize FastMCP server
try:
    app = FastMCP("Stand Up Sydney MCP Server")
    logger.info("FastMCP server initialized successfully")
except Exception as e:
    logger.error(f"Failed to initialize FastMCP server: {e}")
    sys.exit(1)

# Server configuration
SERVER_CONFIG = {
    "name": "Stand Up Sydney FastMCP",
    "version": "1.1.0",
    "host": "170.64.129.59",  # Updated IP
    "port": 8080,
    "deployed_at": datetime.now().isoformat(),
    "platform": "comedy_booking_automation"
}

# Tool configurations for Stand Up Sydney platform
TOOL_CONFIGS = {
    "supabase": {
        "url": os.getenv("SUPABASE_URL", ""),
        "key": os.getenv("SUPABASE_ANON_KEY", ""),
        "enabled": bool(os.getenv("SUPABASE_URL")),
        "description": "Backend API operations for Stand Up Sydney database"
    },
    "github": {
        "token": os.getenv("GITHUB_TOKEN", ""),
        "enabled": bool(os.getenv("GITHUB_TOKEN")),
        "description": "Version control and deployment tracking"
    },
    "notion": {
        "token": os.getenv("NOTION_TOKEN", ""),
        "enabled": bool(os.getenv("NOTION_TOKEN")),
        "description": "Project logging, tasks, and documentation"
    },
    "metricool": {
        "api_key": os.getenv("METRICOOL_API_KEY", ""),
        "enabled": bool(os.getenv("METRICOOL_API_KEY")),
        "description": "Social media promotion and analytics"
    },
    "playwright": {
        "enabled": True,
        "description": "Playwright browser automation for testing and web scraping"
    },
    "filesystem": {
        "enabled": True,
        "description": "File operations for content management"
    }
}

@app.tool()
def health_check() -> Dict[str, Any]:
    """Health check endpoint for the FastMCP server"""
    enabled_tools = [name for name, config in TOOL_CONFIGS.items() if config["enabled"]]
    
    return {
        "status": "healthy",
        "server": SERVER_CONFIG,
        "tools_enabled": enabled_tools,
        "tools_count": len(enabled_tools),
        "timestamp": datetime.now().isoformat(),
        "deployment": "droplet_170.64.129.59",
        "python_version": sys.version,
        "environment_vars": {
            "SUPABASE_URL": bool(os.getenv("SUPABASE_URL")),
            "GITHUB_TOKEN": bool(os.getenv("GITHUB_TOKEN")),
            "NOTION_TOKEN": bool(os.getenv("NOTION_TOKEN")),
            "METRICOOL_API_KEY": bool(os.getenv("METRICOOL_API_KEY"))
        }
    }

@app.tool()
def list_tools() -> Dict[str, Any]:
    """List all available MCP tools and their status"""
    tools_status = {}
    for name, config in TOOL_CONFIGS.items():
        tools_status[name] = {
            "enabled": config["enabled"],
            "description": config["description"],
            "configured": bool(config.get("token") or config.get("api_key") or config.get("url") or config["enabled"])
        }
    
    return {
        "tools": tools_status,
        "total_tools": len(TOOL_CONFIGS),
        "enabled_tools": len([c for c in TOOL_CONFIGS.values() if c["enabled"]]),
        "server_config": SERVER_CONFIG
    }

@app.tool()
def server_diagnostics() -> Dict[str, Any]:
    """Diagnose server configuration and environment"""
    import platform
    
    # Check if all required modules are available
    module_status = {}
    required_modules = ['fastmcp', 'supabase', 'github', 'notion_client', 'dotenv', 'uvicorn']
    
    for module in required_modules:
        try:
            __import__(module)
            module_status[module] = "available"
        except ImportError:
            module_status[module] = "missing"
    
    return {
        "platform_info": {
            "system": platform.system(),
            "python_version": platform.python_version(),
            "architecture": platform.architecture()[0]
        },
        "module_status": module_status,
        "environment_variables": {
            "PORT": os.getenv("PORT", "8080"),
            "HOST": os.getenv("HOST", "0.0.0.0"),
            "SUPABASE_URL_SET": bool(os.getenv("SUPABASE_URL")),
            "GITHUB_TOKEN_SET": bool(os.getenv("GITHUB_TOKEN"))
        },
        "file_system": {
            "working_directory": os.getcwd(),
            "log_directory": str(log_dir),
            "log_file_exists": log_file.exists() if 'log_file' in locals() else False,
            "env_file_exists": Path("/opt/standup-sydney-mcp/.env").exists()
        },
        "timestamp": datetime.now().isoformat()
    }

# ============================================================================
# SIMPLIFIED MCP TOOLS (Implementation Stubs)
# ============================================================================

@app.tool()
def supabase_query(table: str, operation: str = "select", filters: Dict[str, Any] = None, data: Dict[str, Any] = None) -> Dict[str, Any]:
    """Execute Supabase database operations for Stand Up Sydney platform"""
    if not TOOL_CONFIGS["supabase"]["enabled"]:
        return {"error": "Supabase tool not enabled - check SUPABASE_URL and SUPABASE_ANON_KEY"}
    
    logger.info(f"Supabase operation: {operation} on {table}")
    
    return {
        "operation": operation,
        "table": table,
        "filters": filters or {},
        "data": data or {},
        "status": "ready_for_implementation",
        "message": f"FastMCP ready to execute {operation} on {table} table",
        "timestamp": datetime.now().isoformat()
    }

@app.tool()
def github_operations(repo: str, action: str = "status") -> Dict[str, Any]:
    """GitHub operations for Stand Up Sydney"""
    if not TOOL_CONFIGS["github"]["enabled"]:
        return {"error": "GitHub tool not enabled - check GITHUB_TOKEN"}
    
    logger.info(f"GitHub operation: {action} for {repo}")
    
    return {
        "repo": repo,
        "action": action,
        "status": "ready_for_implementation",
        "timestamp": datetime.now().isoformat()
    }

# ============================================================================
# PLAYWRIGHT MCP TOOLS
# ============================================================================

@app.tool()
def playwright_navigate(url: str, wait_for: str = "load") -> Dict[str, Any]:
    """
    Navigate to a URL using Playwright for testing Stand Up Sydney platform
    
    Args:
        url: URL to navigate to (e.g., https://standup-sydney.vercel.app)
        wait_for: What to wait for (load, networkidle, domcontentloaded)
    """
    logger.info(f"Playwright navigation to {url}")
    
    return {
        "action": "navigate",
        "url": url,
        "wait_for": wait_for,
        "status": "ready_for_implementation",
        "message": f"FastMCP ready to navigate to {url}",
        "timestamp": datetime.now().isoformat()
    }

@app.tool()
def playwright_test_element(selector: str, action: str = "click", text: str = None) -> Dict[str, Any]:
    """
    Test UI elements on Stand Up Sydney platform
    
    Args:
        selector: CSS selector or text selector
        action: Action to perform (click, type, check, screenshot)
        text: Text to type (for type action)
    """
    logger.info(f"Playwright element test: {action} on {selector}")
    
    return {
        "action": "test_element",
        "selector": selector,
        "test_action": action,
        "text": text,
        "status": "ready_for_implementation",
        "message": f"FastMCP ready to {action} on {selector}",
        "timestamp": datetime.now().isoformat()
    }

@app.tool()
def playwright_form_test(form_data: Dict[str, str], submit_selector: str = None) -> Dict[str, Any]:
    """
    Test forms on Stand Up Sydney platform (event creation, comedian signup, etc.)
    
    Args:
        form_data: Dictionary of field selectors and values
        submit_selector: CSS selector for submit button
    """
    logger.info(f"Playwright form test with {len(form_data)} fields")
    
    return {
        "action": "form_test",
        "form_data": form_data,
        "submit_selector": submit_selector,
        "status": "ready_for_implementation",
        "message": f"FastMCP ready to test form with {len(form_data)} fields",
        "timestamp": datetime.now().isoformat()
    }

@app.tool()
def playwright_screenshot(selector: str = None, full_page: bool = False) -> Dict[str, Any]:
    """
    Take screenshots for visual testing of Stand Up Sydney platform
    
    Args:
        selector: CSS selector to screenshot (if None, screenshots viewport)
        full_page: Whether to capture full page
    """
    logger.info(f"Playwright screenshot: selector={selector}, full_page={full_page}")
    
    return {
        "action": "screenshot",
        "selector": selector,
        "full_page": full_page,
        "status": "ready_for_implementation",
        "message": "FastMCP ready to take screenshot",
        "timestamp": datetime.now().isoformat()
    }

@app.tool()
def playwright_performance_test(url: str, metrics: List[str] = None) -> Dict[str, Any]:
    """
    Performance testing for Stand Up Sydney platform
    
    Args:
        url: URL to test
        metrics: List of metrics to collect (load_time, network_requests, etc.)
    """
    if metrics is None:
        metrics = ["load_time", "network_requests", "console_errors"]
    
    logger.info(f"Playwright performance test for {url}")
    
    return {
        "action": "performance_test",
        "url": url,
        "metrics": metrics,
        "status": "ready_for_implementation",
        "message": f"FastMCP ready to test performance of {url}",
        "timestamp": datetime.now().isoformat()
    }

@app.tool()
def playwright_integration_test(test_scenario: str, steps: List[Dict[str, Any]]) -> Dict[str, Any]:
    """
    Full integration testing scenarios for Stand Up Sydney platform
    
    Args:
        test_scenario: Name of the test scenario (e.g., "comedian_booking_flow")
        steps: List of test steps with actions and selectors
    """
    logger.info(f"Playwright integration test: {test_scenario} with {len(steps)} steps")
    
    return {
        "action": "integration_test",
        "test_scenario": test_scenario,
        "steps": steps,
        "total_steps": len(steps),
        "status": "ready_for_implementation",
        "message": f"FastMCP ready to run {test_scenario} integration test",
        "timestamp": datetime.now().isoformat()
    }

def main():
    """Start the FastMCP server with correct API"""
    try:
        logger.info(f"Starting Stand Up Sydney FastMCP Server")
        logger.info(f"Working directory: {os.getcwd()}")
        logger.info(f"Python version: {sys.version}")
        
        enabled_tools = [name for name, config in TOOL_CONFIGS.items() if config['enabled']]
        logger.info(f"Enabled tools: {enabled_tools}")
        
        # Run FastMCP server with stdio transport (correct API)
        logger.info("Starting FastMCP server with stdio transport...")
        app.run()
        
    except Exception as e:
        logger.error(f"Failed to start server: {e}")
        logger.error(f"Error type: {type(e).__name__}")
        import traceback
        logger.error(f"Traceback: {traceback.format_exc()}")
        sys.exit(1)

if __name__ == "__main__":
    main()