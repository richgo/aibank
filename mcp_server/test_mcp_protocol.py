"""Tests for MCP protocol compliance - Task 2.7"""
import json
import subprocess
import sys


def test_mcp_server_can_start():
    """MCP server should start without errors"""
    # This test will fail until we implement proper MCP server
    # For now, just check that the module can be imported
    from mcp_server import mcp_server
    assert mcp_server is not None


def test_mcp_server_tool_discovery():
    """MCP server should respond to tool discovery and list all banking tools"""
    # This is a placeholder test - proper MCP tool discovery would require
    # running the server process and sending MCP protocol messages
    # For now, verify that tools are defined
    from mcp_server.server import TOOLS
    
    expected_tools = {
        'get_accounts',
        'get_account_detail', 
        'get_transactions',
        'get_mortgage_summary',
        'get_credit_card_statement'
    }
    
    assert set(TOOLS.keys()) == expected_tools
