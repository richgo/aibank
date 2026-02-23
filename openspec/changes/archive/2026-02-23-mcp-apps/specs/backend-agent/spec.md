# Backend Agent Specification Delta

## ADDED Requirements

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

## MODIFIED Requirements

### Requirement: Banking Intent Recognition

The system SHALL understand natural language banking queries and map them to appropriate MCP tool calls, including transaction location queries.

(Previously: Only recognized account overview, transaction history, and mortgage/credit/savings detail intents.)

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
