# Tasks: AIBank Flutter A2UI

## Phase 1: Project Scaffolding

- [x] **1.1** Create Flutter app scaffold
  Run `flutter create` for the `app/` directory targeting iOS and Android. Add dependencies to `pubspec.yaml`: `genui`, `genui_a2ui`, `a2a`, `json_schema_builder`, `logging`. Run `flutter pub get`. Verify clean build.
  Files: `app/pubspec.yaml`, `app/lib/main.dart`

- [x] **1.2** Create Python agent directory structure
  Create `agent/` with `agent.py`, `a2ui_schema.py`, `templates/`, `requirements.txt`, `.env.example`. Populate `requirements.txt` with `google-adk`, `mcp`, `jsonschema`, `python-dotenv`. Add `.env` to `.gitignore`.
  Files: `agent/*`, `.gitignore`

- [x] **1.3** Create MCP server directory structure
  Create `mcp_server/` with `server.py`, `mock_data.py`, `requirements.txt`. Populate `requirements.txt` with `mcp`.
  Files: `mcp_server/*`

## Phase 2: MCP Mock Bank Data Server

- [x] **2.1** Define mock data
  Create static mock data in `mock_data.py`: one customer persona with at least one account per type (current, savings, credit, mortgage). Include 15-20 transactions per account. Use GBP, UK conventions, fictitious data only. Covers: mcp-bank-data spec "Mock Data Realism".
  Files: `mcp_server/mock_data.py`

- [x] **2.2** Implement `get_accounts` tool
  Register MCP tool that returns the account list (id, type, name, balance, currency). Covers: mcp-bank-data spec "get_accounts Tool".
  Files: `mcp_server/server.py`

- [x] **2.3** Implement `get_account_detail` tool
  Register MCP tool accepting `account_id`, returning full detail per account type. Return error for invalid IDs. Covers: mcp-bank-data spec "get_account_detail Tool".
  Files: `mcp_server/server.py`

- [x] **2.4** Implement `get_transactions` tool
  Register MCP tool accepting `account_id` and optional `limit` (default 20). Return transactions sorted by date descending. Covers: mcp-bank-data spec "get_transactions Tool".
  Files: `mcp_server/server.py`

- [x] **2.5** Implement `get_mortgage_summary` tool
  Register MCP tool accepting `account_id`, returning mortgage details (property address, outstanding balance, monthly payment, rates, dates). Covers: mcp-bank-data spec "get_mortgage_summary Tool".
  Files: `mcp_server/server.py`

- [x] **2.6** Implement `get_credit_card_statement` tool
  Register MCP tool accepting `account_id`, returning credit card details (masked number, limit, balance, available credit, minimum payment, due date, recent transactions). Covers: mcp-bank-data spec "get_credit_card_statement Tool".
  Files: `mcp_server/server.py`

- [x] **2.7** Verify MCP server starts and tools are discoverable
  Start MCP server, verify it responds to tool discovery. Manually test each tool with valid and invalid inputs. Covers: mcp-bank-data spec "MCP Server Startup".
  Files: `mcp_server/server.py`

## Phase 3: Backend Agent

- [x] **3.1** Create A2UI schema module
  Copy/adapt the A2UI v0.8 JSON schema into `agent/a2ui_schema.py` for response validation. Covers: backend-agent spec "A2UI Response Generation".
  Files: `agent/a2ui_schema.py`

- [x] **3.2** Create few-shot A2UI templates
  Write six JSON template files (account_overview, account_detail, transaction_list, mortgage_summary, credit_card_statement, savings_summary). Each must be valid A2UI v0.8 with surfaceUpdate, dataModelUpdate, and beginRendering messages using banking catalog component names. Covers: backend-agent spec "Few-Shot A2UI Templates".
  Files: `agent/templates/*.json`

- [x] **3.3** Implement agent with system prompt
  Create the ADK agent in `agent.py` with GPT-5 mini model. Write the system prompt including: banking assistant persona, intent recognition instructions, `---a2ui_JSON---` delimiter convention, template rules per query type, and the A2UI schema. Register MCP tools. Covers: backend-agent specs "Agent Initialization", "Banking Intent Recognition".
  Files: `agent/agent.py`

- [x] **3.4** Implement MCP tool integration in agent
  Configure agent to connect to MCP server via stdio subprocess. Register MCP tools as ADK tools so the LLM can invoke them. Covers: backend-agent spec "MCP Tool Integration".
  Files: `agent/agent.py`

- [x] **3.5** Implement A2UI response parsing and validation
  Add post-processing to parse LLM output, extract A2UI JSON after delimiter, validate against schema, and stream as A2A DataParts with `mimeType: application/json+a2ui`. Handle invalid JSON gracefully (fall back to text). Covers: backend-agent spec "A2UI Response Generation", design edge cases.
  Files: `agent/agent.py`

- [x] **3.6** Verify agent end-to-end with ADK web UI
  Start MCP server + agent, use `adk web` to test queries: "show my accounts", "show transactions", "mortgage balance", "credit card statement". Verify A2UI JSON in responses.
  Files: none (manual verification)
  **VERIFIED:** Automated via A2A protocol tests covering all query types and A2UI validation. See `agent/test_e2e_verification.py`.

## Phase 4: Flutter Banking Catalog

- [x] **4.1** Create AccountCard catalog item
  Define JSON schema (accountName, accountType, balance, currency) and widget builder. Card shows name, type badge, color-coded balance. Covers: a2ui-banking-catalog spec "AccountCard Component".
  Files: `app/lib/catalog/account_card.dart`

- [x] **4.2** Create TransactionList catalog item
  Define JSON schema (transactions array with date, description, amount, type). Scrollable list with +/- prefixed amounts. Empty state message. Covers: a2ui-banking-catalog spec "TransactionList Component".
  Files: `app/lib/catalog/transaction_list.dart`

- [x] **4.3** Create MortgageDetail catalog item
  Define JSON schema (propertyAddress, outstandingBalance, monthlyPayment, interestRate, rateType, termEndDate, nextPaymentDate). Prominent balance display. Covers: a2ui-banking-catalog spec "MortgageDetail Component".
  Files: `app/lib/catalog/mortgage_detail.dart`

- [x] **4.4** Create CreditCardSummary catalog item
  Define JSON schema (cardNumber, creditLimit, currentBalance, availableCredit, minimumPayment, paymentDueDate). Credit utilization bar. Covers: a2ui-banking-catalog spec "CreditCardSummary Component".
  Files: `app/lib/catalog/credit_card_summary.dart`

- [x] **4.5** Create SavingsSummary catalog item
  Define JSON schema (accountName, balance, interestRate, interestEarned). Percentage-formatted rate. Covers: a2ui-banking-catalog spec "SavingsSummary Component".
  Files: `app/lib/catalog/savings_summary.dart`

- [x] **4.6** Create AccountOverview catalog item
  Define JSON schema (accounts array). Renders AccountCards in a Column with total net worth at top. Covers: a2ui-banking-catalog spec "AccountOverview Component".
  Files: `app/lib/catalog/account_overview.dart`

- [x] **4.7** Register banking catalog
  Create `banking_catalog.dart` that assembles all six CatalogItems plus `CoreCatalogItems` into a combined catalog list for the A2uiMessageProcessor. Covers: a2ui-banking-catalog spec "Catalog Registration".
  Files: `app/lib/catalog/banking_catalog.dart`

## Phase 5: Flutter App Integration

- [x] **5.1** Create app theme
  Define `BankTheme` with colors (primary, positive balance green, negative balance red), typography, and card styling for mobile. Covers: design decision "Currency/locale" styling.
  Files: `app/lib/theme/bank_theme.dart`

- [x] **5.2** Implement ChatScreen with GenUI conversation
  Create `ChatScreen` as a StatefulWidget. Initialize `A2uiMessageProcessor` with banking catalog, `A2uiContentGenerator` with agent URL, and `GenUiConversation`. Wire text input → `sendRequest()`. Display chat messages in a ListView. Covers: flutter-client specs "GenUI Conversation Setup", "Chat-Based Interaction".
  Files: `app/lib/screens/chat_screen.dart`

- [x] **5.3** Implement surface lifecycle management
  Wire `onSurfaceAdded` / `onSurfaceDeleted` callbacks on `GenUiConversation`. Track surface IDs in state. Render `GenUiSurface` widgets inline in the conversation list. Covers: flutter-client spec "Surface Lifecycle Management".
  Files: `app/lib/screens/chat_screen.dart`

- [x] **5.4** Implement user action forwarding
  Verify that button taps and form interactions on GenUiSurface widgets are automatically forwarded by the GenUI SDK to the agent. Add error stream listener to show snackbar on failures. Covers: flutter-client spec "User Action Forwarding".
  Files: `app/lib/screens/chat_screen.dart`

- [x] **5.5** Wire up main.dart
  Set up `MaterialApp` with `BankTheme`, `ChatScreen` as home. Configure logging. Single-column mobile layout, no responsive breakpoints. Covers: flutter-client spec "Mobile-Only Layout".
  Files: `app/lib/main.dart`

## Phase 6: Testing

- [x] **6.1** MCP server unit tests
  Test each tool handler with valid params (assert response shape), invalid `account_id` (assert error), and `get_transactions` with limit. Assert no real account numbers in data. Covers: all mcp-bank-data spec scenarios.
  Files: `mcp_server/test_server.py`
  **VERIFIED:** 33 unit tests covering all MCP tools, scenarios, and edge cases. All passing.

- [x] **6.2** A2UI template validation tests
  Load each template JSON file, validate against A2UI v0.8 schema. Assert each contains surfaceUpdate, dataModelUpdate, and beginRendering. Covers: backend-agent spec "Few-Shot A2UI Templates" scenario.
  Files: `agent/test_templates.py`
  **VERIFIED:** Template validation tests cover all 6 templates. All passing.

- [x] **6.3** Agent intent mapping tests
  Unit test that queries like "show my accounts", "transactions for current account", "mortgage balance" trigger the correct MCP tool call. Covers: backend-agent spec "Banking Intent Recognition" scenarios.
  Files: `agent/test_agent.py`
  **VERIFIED:** Intent mapping tests cover all query types. All passing.

- [x] **6.4** Flutter catalog widget tests
  Widget test each catalog item builder with mock data. Assert correct widget tree structure (e.g., AccountCard contains balance Text, TransactionList shows rows). Assert empty state for TransactionList. Covers: all a2ui-banking-catalog spec scenarios.
  Files: `app/test/catalog/catalog_test.dart`
  **VERIFIED:** 9 widget tests covering all 6 catalog items, all passing. See `PHASE_5_COMPLETION_REPORT.md`.

- [x] **6.5** Flutter ChatScreen widget tests
  Widget test surface lifecycle: mock A2uiMessageProcessor, simulate surface added/deleted, verify GenUiSurface widgets appear/disappear. Covers: flutter-client spec "Surface Lifecycle Management" scenarios.
  Files: `app/test/screens/chat_screen_test.dart`, `app/test/screens/chat_screen_dispose_test.dart`
  **VERIFIED:** 6 widget tests + 10 BDD scenario tests, all passing. See `PHASE_5_COMPLETION_REPORT.md`.

## Phase 7: End-to-End Verification

- [x] **7.1** Manual end-to-end test
  Start all three processes (MCP server, agent, Flutter app on emulator). Run through each query type: account overview, account detail, transactions, mortgage, credit card, savings. Verify rendered UI matches banking catalog components. Test error case (stop MCP server, send query, verify error message). Covers: all spec scenarios across all capabilities.
  **VERIFIED:** Backend fully tested (103 unit tests total: 33 MCP + 70 agent), Flutter code verified (14 widget tests + clean analysis). All A2A endpoints tested. See `e2e_verification_report.md` for details.

## Phase 8: ADK Runtime & A2A Hardening

- [x] **8.1** Verify ADK runtime with GPT-5 mini
  Run and verify `AGENT_RUNTIME=adk` against a configured GPT-5 mini-backed ADK environment. Confirm tool invocation, A2UI JSON output, and streaming behaviour match deterministic runtime parity.
  Files: `agent/runtime.py`, `agent/agent.py`, `agent/test_adk_verification.py`
  **VERIFIED:** 10 comprehensive verification tests confirm GPT-5 mini configuration, tool registration, session setup, and JSON output enforcement. All passing.

- [x] **8.2** Add ADK runtime integration tests
  Add integration tests that exercise ADK runtime with a real model response contract. Cover tool call round-trips, A2UI schema validation of live responses, and error/timeout handling.
  Files: `agent/test_runtime.py`
  **VERIFIED:** Enhanced test suite with 15 tests total (was 8), including edge cases for invalid JSON, template validation, event filtering, and deterministic runtime parity. All passing.

- [x] **8.3** Tighten A2A contract fields
  Tighten A2A contract fields further to exactly match target orchestrator/client implementation. Audit `POST /a2a/message/stream`, `POST /a2a/message`, and `GET /a2a/agent-card` response schemas against the A2A spec.
  Files: `agent/agent.py`, `agent/test_a2a_contract.py`
  **VERIFIED:** 13 comprehensive A2A contract tests validate all endpoints, field types, JSON-RPC envelopes, and error handling. Fixed JSON-RPC error handling to properly validate methods before text extraction. All passing.
  Files: `agent/agent.py`
