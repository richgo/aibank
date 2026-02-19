# MCP Bank Data Specification Delta

## ADDED Requirements

### Requirement: MCP Server Startup

The system SHALL provide an MCP server that exposes mock banking data as tools.

#### Scenario: MCP Server Starts

- GIVEN the MCP server process is launched
- WHEN initialization completes
- THEN the server is reachable and responds to tool discovery requests
- AND all banking tools are registered

### Requirement: get_accounts Tool

The system SHALL provide a `get_accounts` tool that returns a list of all customer accounts.

#### Scenario: Retrieve All Accounts

- GIVEN the MCP server is running
- WHEN `get_accounts` is called with no parameters
- THEN the response contains a JSON array of accounts
- AND each account includes: `id`, `type` (current|savings|credit|mortgage), `name`, `balance`, `currency`

#### Scenario: Account Types Present

- GIVEN mock data is loaded
- WHEN `get_accounts` is called
- THEN at least one account of each type (current, savings, credit, mortgage) is returned

### Requirement: get_account_detail Tool

The system SHALL provide a `get_account_detail` tool that returns detailed information for a specific account.

#### Scenario: Retrieve Current Account Detail

- GIVEN a valid current account ID
- WHEN `get_account_detail` is called with that ID
- THEN the response includes: `id`, `name`, `balance`, `currency`, `accountNumber`, `sortCode`, `overdraftLimit`

#### Scenario: Retrieve Savings Account Detail

- GIVEN a valid savings account ID
- WHEN `get_account_detail` is called with that ID
- THEN the response includes: `id`, `name`, `balance`, `currency`, `interestRate`, `interestEarned`, `accountNumber`

#### Scenario: Invalid Account ID

- GIVEN an account ID that does not exist
- WHEN `get_account_detail` is called with that ID
- THEN the response returns an error with message "Account not found"

### Requirement: get_transactions Tool

The system SHALL provide a `get_transactions` tool that returns transaction history for an account.

#### Scenario: Retrieve Transactions

- GIVEN a valid account ID
- WHEN `get_transactions` is called with that ID
- THEN the response contains a JSON array of transactions
- AND each transaction includes: `id`, `date`, `description`, `amount`, `currency`, `type` (debit|credit), `runningBalance`

#### Scenario: Retrieve Transactions with Limit

- GIVEN a valid account ID and a `limit` parameter of 5
- WHEN `get_transactions` is called with those parameters
- THEN at most 5 transactions are returned
- AND they are ordered by date descending (most recent first)

### Requirement: get_mortgage_summary Tool

The system SHALL provide a `get_mortgage_summary` tool that returns mortgage account details.

#### Scenario: Retrieve Mortgage Summary

- GIVEN a valid mortgage account ID
- WHEN `get_mortgage_summary` is called with that ID
- THEN the response includes: `id`, `propertyAddress`, `originalAmount`, `outstandingBalance`, `monthlyPayment`, `interestRate`, `rateType` (fixed|variable), `termEndDate`, `nextPaymentDate`

### Requirement: get_credit_card_statement Tool

The system SHALL provide a `get_credit_card_statement` tool that returns credit card details.

#### Scenario: Retrieve Credit Card Statement

- GIVEN a valid credit card account ID
- WHEN `get_credit_card_statement` is called with that ID
- THEN the response includes: `id`, `cardNumber` (masked, last 4 digits only), `creditLimit`, `currentBalance`, `availableCredit`, `minimumPayment`, `paymentDueDate`, `recentTransactions`

### Requirement: Mock Data Realism

The system SHALL use realistic but clearly fictitious mock data.

#### Scenario: Mock Data is Realistic

- GIVEN the MCP server is running
- WHEN any tool is called
- THEN amounts are in GBP with realistic values (e.g., current balance £2,450.67, mortgage £187,500.00)
- AND descriptions reference realistic merchants and payees
- AND dates span the last 90 days

#### Scenario: Mock Data is Clearly Fictitious

- GIVEN the MCP server is running
- WHEN any tool is called
- THEN no real bank account numbers, sort codes, or card numbers are used
- AND the customer name is a fictitious persona
