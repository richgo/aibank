# Proposal: AIBank Flutter A2UI

## Intent

Banking customers need a modern, AI-driven interface that can dynamically generate rich UI for account management — showing balances, transactions, and product details across current accounts, savings, credit cards, and mortgages. Today there is no application; this is a greenfield build.

The core problem is: **how do we let an AI agent present structured financial data as native, interactive UI rather than plain text?** A2UI solves this by enabling agents to stream declarative component descriptions that render natively in Flutter.

## Scope

### In Scope
- Flutter client app using the GenUI SDK (`flutter_genui`, `genui_a2ui`) to render A2UI surfaces
- Backend AI agent (Python/ADK) that generates A2UI JSON for banking queries
- MCP server exposing mock bank data as tools/resources for the agent
- Mock data for four product types: current account, savings account, credit card, mortgage
- Account overview dashboard (balances, recent transactions)
- Account detail views per product type
- Chat-style interaction for natural language banking queries
- A2A transport between Flutter client and backend agent

### Out of Scope
- Real banking APIs or live data
- Authentication / authorization / security hardening
- Payment initiation or fund transfers
- Biometric or 2FA flows
- Production deployment, CI/CD
- Push notifications
- Multi-user or multi-tenancy

## Approach

**Client (Flutter + GenUI SDK):**
Use `genui_a2ui` package to connect to the backend agent via A2A. Define a custom widget catalog with banking-specific components (AccountCard, TransactionList, MortgageDetail, etc.) that the agent can compose. The `GenUiConversation` orchestrates user input → agent → rendered surfaces.

**Backend Agent (Python + ADK):**
A GPT-5 mini powered agent (via GitHub Copilot subscription) that understands banking intent, calls MCP tools to retrieve mock data, and generates A2UI JSON responses. The agent instruction set includes few-shot A2UI templates for each query type (overview, detail, transaction list).

**MCP Server (Mock Bank Data):**
An MCP server providing tools such as `get_accounts`, `get_account_detail`, `get_transactions`, `get_mortgage_summary`, `get_credit_card_statement`. Returns realistic mock data (multiple accounts, varied transaction histories, mortgage amortization details).

**Integration pattern:**
```
User ──→ Flutter (GenUI) ──→ A2A ──→ Agent (ADK + Gemini)
                                         │
                                    MCP Tools
                                         │
                                    Mock Bank Data
```

## Impact

- **New repository structure** — Flutter project, Python agent, MCP server as separate directories
- **No existing code affected** — greenfield project
- **Dependencies introduced:**
  - Flutter: `genui`, `genui_a2ui`, `a2a`
  - Python: `google-adk`, `mcp` SDK, A2UI schema utilities, GitHub Copilot (GPT-5 mini)
- **New spec area** — establishes patterns for future AI-driven banking features

## Risks

- **A2UI is v0.8 (Public Preview)** — spec and implementations are still evolving; breaking changes possible
- **GenUI SDK is new** — limited community examples; debugging may require reading source
- **LLM UI generation quality** — A2UI JSON generation depends on prompt engineering; complex banking UIs may need extensive few-shot examples
- **MCP + A2UI integration is novel** — no established reference pattern for combining MCP tools with A2UI agent output; will require experimentation
- **Mock data fidelity** — mock data needs to be realistic enough to demonstrate real banking scenarios without being mistaken for real financial data

## Decisions

- **Model:** GPT-5 mini via GitHub Copilot subscription — no separate API key management needed, cost-effective for structured JSON output
- **Platform:** Mobile only (iOS + Android) — simplifies layout concerns, avoids responsive breakpoint complexity
- **Widget catalog:** Banking-specific components (AccountCard, TransactionList, MortgageDetail, CreditCardStatement, etc.) — domain-focused, easier for the agent to select the right component

## Open Question: MCP Tool Response Format

**Option A — Raw data (agent formats into A2UI):**

| Pro | Con |
|-----|-----|
| MCP tools stay UI-agnostic and reusable by other consumers | Agent must do more work per request; larger prompt with UI schema |
| Agent can adapt presentation to context (e.g., summary vs detail) | More token usage; higher latency |
| Clean separation of data layer and presentation layer | UI quality depends entirely on prompt engineering |
| MCP tools are simpler to build and test | |

**Option B — Pre-formatted A2UI fragments from MCP tools:**

| Pro | Con |
|-----|-----|
| Deterministic, pixel-perfect UI every time | MCP tools become tightly coupled to A2UI spec version |
| Minimal token usage; agent just passes through | Tools not reusable outside A2UI clients |
| Faster response; less LLM reasoning needed | Loses the "AI generates adaptive UI" value proposition |
| Easier to test and debug | Harder to maintain as catalog evolves |

**✅ Decision: Option C — Hybrid:**
MCP tools return **raw data**. The agent has a library of **few-shot A2UI templates** in its system prompt for each query type. The agent maps data → template, filling in values. This gives:
- Reusable MCP tools (raw data)
- Consistent UI quality (templates)
- Agent flexibility to choose layout based on context
- Manageable prompt size (templates are small)
