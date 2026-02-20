# MCP-Apps Protocol Specification Delta

## ADDED Requirements

### Requirement: MCP-App Manifest

The system SHALL support an MCP-App manifest that declares A2UI components provided by an external MCP server.

#### Scenario: Manifest Contains Component Schemas

- GIVEN an MCP-App manifest for Google Maps
- WHEN the manifest is parsed
- THEN it contains a `components` array with at least one component definition
- AND each component has a `name`, `namespace`, and `dataSchema`

#### Scenario: Manifest Declares Namespace

- GIVEN an MCP-App manifest
- WHEN the manifest is loaded
- THEN it declares a `namespace` identifier (e.g., `googlemaps`)
- AND all components from this manifest are prefixed with that namespace

### Requirement: Namespaced Component Identifiers

The system SHALL use namespaced identifiers for MCP-App components to prevent collisions with internal catalog items.

#### Scenario: External Component Uses Namespace Prefix

- GIVEN the agent constructs a surface with an MCP-App component
- WHEN the component is from the Google Maps MCP-App
- THEN the component name is prefixed as `googlemaps:MapView`
- AND internal components remain unprefixed (e.g., `AccountCard`)

#### Scenario: Namespace Separator Is Colon

- GIVEN a namespaced component identifier
- WHEN parsed by the client
- THEN the namespace and component name are separated by a single colon character
- AND the format is `{namespace}:{ComponentName}`

### Requirement: MCP-App Configuration

The system SHALL support deployment-time configuration of MCP-App endpoints and credentials.

#### Scenario: Google Maps MCP-App Configured

- GIVEN the agent deployment configuration
- WHEN the Google Maps MCP-App is enabled
- THEN the configuration includes the MCP server endpoint URL
- AND the configuration includes any required API keys

#### Scenario: MCP-App Disabled by Default

- GIVEN no MCP-App configuration is provided
- WHEN the agent starts
- THEN no external MCP-Apps are connected
- AND the agent operates with internal MCP tools only
