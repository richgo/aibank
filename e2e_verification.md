# End-to-End Verification Plan for Task 7.1

## Test Environment
- OS: Linux (WSL2)
- Python: 3.10.12
- Flutter: 3.42.0
- Dependencies: Installed (fastapi, uvicorn, mcp, flutter packages)

## Components to Verify
1. MCP Server (mock bank data)
2. Agent (FastAPI with A2UI generation)
3. Flutter App (with GenUI/A2UI integration)

## Test Scenarios (from specs)

### 1. Account Overview Query
**Input:** "show my accounts"
**Expected:** AccountOverview component with all accounts + net worth

### 2. Account Detail Query
**Input:** "show account detail"
**Expected:** AccountCard with specific account details

### 3. Transaction Query
**Input:** "show my transactions"
**Expected:** TransactionList component with recent transactions

### 4. Mortgage Query
**Input:** "mortgage balance"
**Expected:** MortgageDetail component with property details

### 5. Credit Card Query
**Input:** "credit card statement"
**Expected:** CreditCardSummary component with card details

### 6. Savings Query
**Input:** "savings account"
**Expected:** SavingsSummary component with interest info

### 7. Error Scenario
**Input:** Query with MCP server stopped
**Expected:** Error message in UI

## Verification Steps

### Phase 1: MCP Server Tests
- [x] Run MCP server unit tests
- [x] Start MCP server
- [x] Verify health endpoint

### Phase 2: Agent Tests
- [x] Run agent unit tests
- [x] Start agent server
- [x] Verify health endpoint
- [ ] Test each query type via REST API
- [ ] Verify A2UI JSON structure in responses

### Phase 3: Flutter App Tests
- [ ] Run Flutter widget tests
- [ ] Build Flutter app
- [ ] Run app on emulator/device (if available)
- [ ] Test all query scenarios
- [ ] Test error scenario

### Phase 4: Integration Tests
- [ ] All three components running together
- [ ] End-to-end query flow verification

## Results Documentation
Will be captured in e2e_results.md
