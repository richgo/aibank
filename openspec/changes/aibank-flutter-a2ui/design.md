# Design: AIBank Flutter A2UI

## Overview

A mobile-only Flutter app communicates with a Python backend agent over A2A protocol. The agent uses GPT-5 mini (Copilot) to interpret banking queries, invokes MCP tools to fetch mock data, and streams A2UI JSON back to the client. The Flutter GenUI SDK renders banking-specific catalog widgets. The system is three independent processes: Flutter app, Python agent, and MCP server.

## Architecture

### Components Affected

None — greenfield project.

### New Components

```
aibank/
├── app/                          # Flutter mobile app
│   ├── lib/
│   │   ├── main.dart             # Entry point, conversation setup
│   │   ├── screens/
│   │   │   └── chat_screen.dart  # Main chat + surface view
│   │   ├── catalog/
│   │   │   ├── banking_catalog.dart      # Catalog registration
│   │   │   ├── account_card.dart         # AccountCard widget + schema
│   │   │   ├── transaction_list.dart     # TransactionList widget + schema
│   │   │   ├── mortgage_detail.dart      # MortgageDetail widget + schema
│   │   │   ├── credit_card_summary.dart  # CreditCardSummary widget + schema
│   │   │   ├── savings_summary.dart      # SavingsSummary widget + schema
│   │   │   └── account_overview.dart     # AccountOverview widget + schema
│   │   └── theme/
│   │       └── bank_theme.dart   # App theme and colors
│   ├── pubspec.yaml
│   └── ios/ android/             # Platform runners
│
├── agent/                        # Python backend agent
│   ├── agent.py                  # ADK agent definition, system prompt, templates
│   ├── a2ui_schema.py            # A2UI v0.8 JSON schema for validation
│   ├── templates/                # Few-shot A2UI JSON templates
│   │   ├── account_overview.json
│   │   ├── account_detail.json
│   │   ├── transaction_list.json
│   │   ├── mortgage_summary.json
│   │   ├── credit_card_statement.json
│   │   └── savings_summary.json
│   ├── requirements.txt
│   └── .env                      # COPILOT_API_KEY (gitignored)
│
└── mcp_server/                   # MCP mock bank data server
    ├── server.py                 # MCP server with tool handlers
    ├── mock_data.py              # Static mock data definitions
    └── requirements.txt
```

## Technical Decisions

### Decision: Agent Framework

**Chosen:** Google ADK (Agent Development Kit) with GPT-5 mini model via Copilot

**Alternatives considered:**
- LangChain — rejected because ADK has native A2UI schema support and first-class A2A integration; LangChain adds abstraction overhead without A2UI benefits
- Raw OpenAI SDK — rejected because ADK provides tool management, conversation history, and A2A serving out of the box

**Rationale:** ADK is the reference framework for A2UI agents, reducing integration friction. GPT-5 mini via Copilot avoids separate API key management and leverages the existing subscription.

### Decision: Transport Protocol

**Chosen:** A2A protocol via `genui_a2ui` package

**Alternatives considered:**
- Direct WebSocket — rejected because A2A provides catalog negotiation, extension activation, and structured DataPart encoding; raw WebSocket would require reimplementing these
- REST polling — rejected because A2UI requires streaming (JSONL over SSE); polling adds latency and defeats progressive rendering

**Rationale:** A2A is the native transport for A2UI with built-in support in both ADK (server) and `genui_a2ui` (client). It handles catalog capability exchange automatically.

### Decision: MCP Server Implementation

**Chosen:** Python MCP SDK with stdio transport, launched as a subprocess by the agent

**Alternatives considered:**
- MCP over HTTP/SSE — rejected because the agent and MCP server are co-located; stdio is simpler and has zero network overhead
- Embedded mock data directly in agent — rejected because MCP provides a clean tool interface that can be swapped for real banking APIs later

**Rationale:** Stdio transport keeps the MCP server as a simple subprocess. The agent's ADK framework supports MCP tool integration natively. The separation means the mock server can be replaced with a real API adapter without changing agent code.

### Decision: Custom Catalog Widget Granularity

**Chosen:** Six banking-specific composite widgets (AccountCard, TransactionList, MortgageDetail, CreditCardSummary, SavingsSummary, AccountOverview)

**Alternatives considered:**
- Fine-grained atomic widgets (BalanceBadge, RatePill, TransactionRow) — rejected because more widgets means more catalog items in the LLM prompt, increasing token usage and reducing selection accuracy
- Single generic "BankingView" widget with mode parameter — rejected because it pushes layout logic into the widget builder, defeating A2UI's declarative model

**Rationale:** Six domain-specific widgets balance specificity (agent knows exactly which widget to use) with manageable catalog size. Each widget owns its own layout. Standard A2UI components (Row, Column, Text, Button) from `CoreCatalogItems` handle surrounding structure.

### Decision: Flutter State Management

**Chosen:** GenUI SDK's built-in `DataModel` + `A2uiMessageProcessor` reactive system

**Alternatives considered:**
- Riverpod/Bloc alongside GenUI — rejected because GenUI's DataModel already provides observable state for surfaces; adding another layer creates dual-source-of-truth complexity
- Provider — same rejection reason

**Rationale:** GenUI SDK manages all A2UI surface state internally. The only app-level state is the conversation message list and surface ID tracking, which a simple `StatefulWidget` with `setState` handles adequately for a chat screen.

### Decision: Mock Data Currency and Locale

**Chosen:** GBP (£), UK banking conventions (sort codes, account numbers)

**Alternatives considered:**
- USD — no strong reason to prefer one over the other
- Multi-currency — rejected because it adds complexity without demonstrating additional A2UI capability

**Rationale:** GBP provides a consistent, realistic banking context. Mock data uses UK-style sort codes (XX-XX-XX) and 8-digit account numbers.

## Data Flow

```
1. User types query in Flutter chat input
2. ChatScreen calls _genUiConversation.sendRequest(UserMessage.text(query))
3. GenUiConversation → A2uiContentGenerator → A2A POST to agent server
4. Agent (ADK) receives message, sends to GPT-5 mini with:
   - System prompt (banking instructions + few-shot A2UI templates)
   - MCP tool definitions
   - Conversation history
5. GPT-5 mini identifies intent, calls MCP tool (e.g., get_accounts)
6. Agent invokes MCP server (stdio subprocess) → mock_data.py returns JSON
7. GPT-5 mini receives tool result, generates A2UI JSON using template patterns
8. Agent parses LLM output, extracts A2UI messages after ---a2ui_JSON--- delimiter
9. Agent validates A2UI JSON against schema
10. Agent streams A2UI messages as A2A DataParts (mimeType: application/json+a2ui)
11. A2uiContentGenerator receives DataParts → emits A2uiMessages
12. A2uiMessageProcessor processes messages → updates DataModel + surface state
13. GenUiSurface rebuilds → banking catalog widget builder renders native Flutter widgets
14. User sees rendered banking UI (e.g., AccountCard with balance)
```

User actions (button taps) follow the reverse path:
```
15. User taps button → GenUiSurface captures action
16. A2uiMessageProcessor constructs userAction with data model snapshot
17. A2uiContentGenerator sends userAction as A2A message to agent
18. Agent processes action → may call MCP tools → generates updated A2UI
19. Steps 10-14 repeat with updated surfaces
```

## API Changes

No existing APIs. New interfaces:

**MCP Tools (agent → MCP server):**
| Tool | Parameters | Returns |
|------|-----------|---------|
| `get_accounts` | none | `Account[]` |
| `get_account_detail` | `account_id: string` | `AccountDetail` |
| `get_transactions` | `account_id: string`, `limit?: int` | `Transaction[]` |
| `get_mortgage_summary` | `account_id: string` | `MortgageSummary` |
| `get_credit_card_statement` | `account_id: string` | `CreditCardStatement` |

**A2A (Flutter ↔ Agent):**
Standard A2A protocol — no custom endpoints. Messages carry A2UI DataParts with `mimeType: application/json+a2ui`.

## Dependencies

**Flutter app (`pubspec.yaml`):**
- `genui` — GenUI SDK core
- `genui_a2ui` — A2A content generator
- `a2a` — A2A protocol types
- `json_schema_builder` — catalog item schema definitions
- `logging` — debug logging

**Python agent (`requirements.txt`):**
- `google-adk` — Agent Development Kit
- `mcp` — MCP Python SDK
- `jsonschema` — A2UI message validation
- `python-dotenv` — env var loading

**Python MCP server (`requirements.txt`):**
- `mcp` — MCP Python SDK

## Migration / Backwards Compatibility

Not applicable — greenfield project with no existing data or behavior.

## Testing Strategy

**Flutter (unit + widget tests):**
- Each catalog widget: unit test that the builder produces correct widget tree from mock data (covers a2ui-banking-catalog specs)
- ChatScreen: widget test verifying surface lifecycle callbacks add/remove GenUiSurface widgets (covers flutter-client specs)
- Integration test: mock A2uiContentGenerator, verify full send → receive → render cycle

**Python agent (unit tests):**
- A2UI template validation: parse each template JSON, validate against A2UI schema (covers backend-agent template spec)
- Intent → tool mapping: unit test that known queries trigger correct MCP tool calls (covers backend-agent intent specs)
- Error handling: test agent response when MCP tool raises exception (covers backend-agent error spec)

**MCP server (unit tests):**
- Each tool handler: call with valid/invalid params, assert response shape and data types (covers all mcp-bank-data specs)
- Mock data realism: assert no real account numbers, amounts in expected ranges (covers mock data realism spec)

**End-to-end (manual):**
- Start MCP server + agent + Flutter app → send each query type → verify rendered UI matches expected layout

## Edge Cases

| Edge Case | Handling |
|-----------|----------|
| MCP server not running | Agent catches connection error, returns Text surface with "Banking services unavailable. Please try again." |
| LLM generates invalid A2UI JSON | Agent validates against schema; on failure, returns plain text response instead of broken UI |
| LLM omits `---a2ui_JSON---` delimiter | Agent treats entire response as text, displays as chat message |
| Empty account list | Agent generates AccountOverview with "No accounts found" Text component |
| Empty transaction list | TransactionList widget shows "No transactions found" message (handled in widget builder) |
| Network timeout (Flutter → Agent) | A2uiContentGenerator error stream fires; ChatScreen shows error snackbar |
| Very long transaction list | `get_transactions` defaults to `limit: 20`; agent can request more via pagination |
| User sends gibberish query | Agent responds with text "I can help you with account balances, transactions, mortgages, and credit cards. What would you like to know?" |
