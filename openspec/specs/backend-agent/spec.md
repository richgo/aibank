# Backend Agent Specification Delta


### Requirement: Agent Initialization

The system SHALL provide a Python-based agent using the ADK framework, configured with GPT-5 mini (via GitHub Copilot subscription) as the LLM.

#### Scenario: Agent Starts Successfully

- GIVEN the agent server is started
- WHEN the agent process initializes
- THEN the agent registers with model `gpt-5-mini` via Copilot
- AND the agent is reachable via A2A protocol on a configured port

### Requirement: Banking Intent Recognition

The system SHALL understand natural language banking queries and map them to appropriate MCP tool calls, including transaction location queries.

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

#### Scenario: User Asks for Transaction Location

- GIVEN the agent receives the message "where was my last Tesco purchase?"
- WHEN the agent processes the intent
- THEN the agent identifies the `transaction_location` intent
- AND the agent calls bank MCP to find matching transactions
- AND the agent calls Google Maps MCP to geocode the merchant

#### Scenario: Location Intent Keywords

- GIVEN the agent receives a message containing "where", "location", "map", or "show me"
- WHEN combined with transaction context
- THEN the agent recognizes the transaction location intent

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

### Requirement: Multi-MCP Server Orchestration

The system SHALL support connecting to multiple MCP servers and orchestrating tool calls across them.

#### Scenario: Agent Connects to Multiple MCP Servers

- GIVEN the agent is configured with bank MCP and Google Maps MCP endpoints
- WHEN the agent starts
- THEN connections are established to both MCP servers
- AND tools from both servers are available for invocation

#### Scenario: Cross-MCP Tool Orchestration

- GIVEN the agent has access to bank MCP and Google Maps MCP
- WHEN the user asks "where was my Tesco transaction?"
- THEN the agent calls `get_transactions` on bank MCP
- AND the agent calls `geocode` on Google Maps MCP with the merchant name
- AND the agent combines results to construct the response

### Requirement: Transaction Location Intent

The system SHALL recognize user intent to view transaction location and respond with a map surface.

#### Scenario: User Asks for Transaction Location

- GIVEN the user has transactions in their account
- WHEN the user asks "where was this transaction?" or "show me on a map"
- THEN the agent identifies the transaction location intent
- AND the agent retrieves the transaction details
- AND the agent geocodes the merchant name via Google Maps MCP

#### Scenario: Agent Generates Map Surface

- GIVEN the agent has geocoded a merchant location
- WHEN constructing the A2UI response
- THEN the response includes a `googlemaps:MapView` component
- AND the component data includes latitude, longitude, and merchant name
- AND the surface is valid A2UI v0.8

### Requirement: Transaction Location Template

The system SHALL include an A2UI template for displaying transaction location with a map.

#### Scenario: Transaction Location Template Structure

- GIVEN the agent loads the transaction location template
- WHEN the template is parsed
- THEN it contains a Column with transaction details and a `googlemaps:MapView` component
- AND the MapView binds to latitude, longitude, and label data paths
