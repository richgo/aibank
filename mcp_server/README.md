# AIBank MCP Server

Provides banking tools (accounts, transactions, mortgage, credit card) as both:
- **Direct Python module** — imported by the agent runtime
- **MCP stdio server** — usable by any MCP-compatible client

## Tools

| Tool | Description |
|---|---|
| `get_accounts` | List all customer accounts |
| `get_account_detail` | Full detail for one account |
| `get_transactions` | Transaction history (newest first) |
| `get_mortgage_summary` | Mortgage balance and payment info |
| `get_credit_card_statement` | Credit card balance and recent transactions |

## Running as an MCP stdio server

Run from the **repository root**:

```bash
python3 -m mcp_server.mcp_server
```

The server communicates over stdin/stdout using the MCP protocol. Connect with any MCP client (e.g., Claude Desktop, VS Code MCP extension).

## Using as a Python module

The agent imports the tools directly — no separate process needed:

```python
from mcp_server.server import call_tool

accounts = call_tool("get_accounts")
txns = call_tool("get_transactions", account_id="acc_current_001", limit=5)
```

## Running tests

From the repository root:

```bash
python3 -m pytest mcp_server/
```
