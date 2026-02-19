# Backend Agent Specification Delta

## ADDED Requirements

### Requirement: Agent Initialization

The system SHALL provide a Python-based agent using the ADK framework, configured with GPT-5 mini (via GitHub Copilot subscription) as the LLM.

#### Scenario: Agent Starts Successfully

- GIVEN the agent server is started
- WHEN the agent process initializes
- THEN the agent registers with model `gpt-5-mini` via Copilot
- AND the agent is reachable via A2A protocol on a configured port

### Requirement: Banking Intent Recognition

The system SHALL understand natural language banking queries and map them to appropriate MCP tool calls.

#### Scenario: User Asks for Account Overview

- GIVEN the agent receives the message "show my accounts"
- WHEN the agent processes the intent
- THEN the agent calls the `get_accounts` MCP tool
- AND generates an A2UI response with account summary cards

#### Scenario: User Asks for Transaction History

- GIVEN the agent receives the message "show transactions for my current account"
- WHEN the agent processes the intent
- THEN the agent calls the `get_transactions` MCP tool with the appropriate account identifier
- AND generates an A2UI response with a transaction list

#### Scenario: User Asks for Mortgage Details

- GIVEN the agent receives the message "what's my mortgage balance?"
- WHEN the agent processes the intent
- THEN the agent calls the `get_mortgage_summary` MCP tool
- AND generates an A2UI response with mortgage detail components

### Requirement: A2UI Response Generation

The system SHALL generate valid A2UI v0.8 JSON messages using few-shot templates for each banking query type.

#### Scenario: Agent Generates Account Overview UI

- GIVEN the agent has retrieved account data from MCP tools
- WHEN the agent constructs the response
- THEN the response contains valid `surfaceUpdate`, `dataModelUpdate`, and `beginRendering` messages
- AND the messages conform to the A2UI v0.8 JSON schema

#### Scenario: Agent Generates Error UI

- GIVEN the MCP tool returns an error or no data
- WHEN the agent constructs the response
- THEN the response contains a surface with an error message Text component
- AND a suggestion for the user to try again

### Requirement: MCP Tool Integration

The system SHALL connect to the MCP bank data server and invoke tools to retrieve account information.

#### Scenario: Agent Calls MCP Tool Successfully

- GIVEN the MCP server is running and healthy
- WHEN the agent invokes `get_accounts`
- THEN the agent receives a JSON payload of account data
- AND uses the data to populate A2UI templates

#### Scenario: MCP Server Unavailable

- GIVEN the MCP server is not reachable
- WHEN the agent attempts to invoke any MCP tool
- THEN the agent responds with a friendly error message to the user
- AND does not crash or hang

### Requirement: Few-Shot A2UI Templates

The system SHALL include A2UI template examples in the agent's system prompt for each supported query type.

#### Scenario: Template Library Covers All Query Types

- GIVEN the agent system prompt is loaded
- WHEN the prompt is inspected
- THEN it contains few-shot A2UI JSON examples for: account overview, account detail, transaction list, mortgage summary, credit card statement, and savings summary
