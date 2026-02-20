# A2UI Banking Catalog Specification Delta


### Requirement: AccountCard Component

The system SHALL provide an `AccountCard` catalog item that displays an account summary.

#### Scenario: Render Account Card

- GIVEN the agent sends a surface with an `AccountCard` component
- WHEN the data model contains `accountName`, `accountType`, `balance`, and `currency`
- THEN a Card widget renders showing the account name, type badge, and formatted balance
- AND the balance is color-coded (positive = green, negative = red)

### Requirement: TransactionList Component

The system SHALL provide a `TransactionList` catalog item that displays a scrollable list of transactions.

#### Scenario: Render Transaction List

- GIVEN the agent sends a surface with a `TransactionList` component
- WHEN the data model contains a list of transactions
- THEN each transaction row shows date, description, and amount
- AND debit amounts are prefixed with "-" and credit amounts with "+"
- AND the list is scrollable

#### Scenario: Empty Transaction List

- GIVEN the agent sends a `TransactionList` with no transactions
- WHEN the surface renders
- THEN a message "No transactions found" is displayed

### Requirement: MortgageDetail Component

The system SHALL provide a `MortgageDetail` catalog item that displays mortgage account information.

#### Scenario: Render Mortgage Detail

- GIVEN the agent sends a surface with a `MortgageDetail` component
- WHEN the data model contains mortgage data
- THEN the component displays: property address, outstanding balance, monthly payment, interest rate, rate type, term end date, and next payment date
- AND the outstanding balance is prominently displayed

### Requirement: CreditCardSummary Component

The system SHALL provide a `CreditCardSummary` catalog item that displays credit card information.

#### Scenario: Render Credit Card Summary

- GIVEN the agent sends a surface with a `CreditCardSummary` component
- WHEN the data model contains credit card data
- THEN the component displays: masked card number, current balance, available credit, credit limit, minimum payment, and payment due date
- AND a visual bar shows credit utilization (balance / limit)

### Requirement: SavingsSummary Component

The system SHALL provide a `SavingsSummary` catalog item that displays savings account details.

#### Scenario: Render Savings Summary

- GIVEN the agent sends a surface with a `SavingsSummary` component
- WHEN the data model contains savings data
- THEN the component displays: account name, balance, interest rate, and interest earned
- AND the interest rate is formatted as a percentage

### Requirement: AccountOverview Component

The system SHALL provide an `AccountOverview` catalog item that displays a summary of all accounts.

#### Scenario: Render Account Overview

- GIVEN the agent sends a surface with an `AccountOverview` component
- WHEN the data model contains a list of accounts
- THEN each account is rendered as an `AccountCard` in a vertical list
- AND a total net worth figure is displayed at the top (sum of all balances)

### Requirement: Catalog Registration

The system SHALL register all banking catalog items with the `A2uiMessageProcessor` at app startup.

#### Scenario: All Banking Components Available

- GIVEN the app initializes
- WHEN the `A2uiMessageProcessor` is created
- THEN the banking catalog containing AccountCard, TransactionList, MortgageDetail, CreditCardSummary, SavingsSummary, and AccountOverview is registered
- AND the core catalog (`CoreCatalogItems`) is also registered for standard components (Text, Row, Column, Button, etc.)
