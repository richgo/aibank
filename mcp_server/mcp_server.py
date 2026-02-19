"""MCP Server implementation for banking tools - Task 2.7"""
from __future__ import annotations

import anyio
from mcp.server import Server
from mcp.server.stdio import stdio_server
from mcp.types import Tool, TextContent

from .server import (
    get_accounts,
    get_account_detail,
    get_transactions,
    get_mortgage_summary,
    get_credit_card_statement,
    ToolError,
)


# Create MCP server instance
app = Server("aibank-mcp-server")


@app.list_tools()
async def list_tools() -> list[Tool]:
    """List all available banking tools"""
    return [
        Tool(
            name="get_accounts",
            description="Get a list of all customer accounts",
            inputSchema={
                "type": "object",
                "properties": {},
                "required": [],
            },
        ),
        Tool(
            name="get_account_detail",
            description="Get detailed information for a specific account",
            inputSchema={
                "type": "object",
                "properties": {
                    "account_id": {
                        "type": "string",
                        "description": "The unique identifier of the account",
                    }
                },
                "required": ["account_id"],
            },
        ),
        Tool(
            name="get_transactions",
            description="Get transaction history for an account",
            inputSchema={
                "type": "object",
                "properties": {
                    "account_id": {
                        "type": "string",
                        "description": "The unique identifier of the account",
                    },
                    "limit": {
                        "type": "integer",
                        "description": "Maximum number of transactions to return (default: 20)",
                        "default": 20,
                    },
                },
                "required": ["account_id"],
            },
        ),
        Tool(
            name="get_mortgage_summary",
            description="Get mortgage account details and payment information",
            inputSchema={
                "type": "object",
                "properties": {
                    "account_id": {
                        "type": "string",
                        "description": "The unique identifier of the mortgage account",
                    }
                },
                "required": ["account_id"],
            },
        ),
        Tool(
            name="get_credit_card_statement",
            description="Get credit card details including balance and transactions",
            inputSchema={
                "type": "object",
                "properties": {
                    "account_id": {
                        "type": "string",
                        "description": "The unique identifier of the credit card account",
                    }
                },
                "required": ["account_id"],
            },
        ),
    ]


@app.call_tool()
async def call_tool(name: str, arguments: dict) -> list[TextContent]:
    """Handle tool calls"""
    try:
        if name == "get_accounts":
            result = get_accounts()
        elif name == "get_account_detail":
            result = get_account_detail(arguments["account_id"])
        elif name == "get_transactions":
            result = get_transactions(
                arguments["account_id"], arguments.get("limit", 20)
            )
        elif name == "get_mortgage_summary":
            result = get_mortgage_summary(arguments["account_id"])
        elif name == "get_credit_card_statement":
            result = get_credit_card_statement(arguments["account_id"])
        else:
            raise ToolError(f"Unknown tool: {name}")

        import json
        return [TextContent(type="text", text=json.dumps(result, indent=2))]
    except ToolError as e:
        return [TextContent(type="text", text=f"Error: {str(e)}")]
    except Exception as e:
        return [TextContent(type="text", text=f"Unexpected error: {str(e)}")]


async def main():
    """Run the MCP server"""
    async with stdio_server() as (read_stream, write_stream):
        await app.run(read_stream, write_stream, app.create_initialization_options())


if __name__ == "__main__":
    anyio.run(main)
