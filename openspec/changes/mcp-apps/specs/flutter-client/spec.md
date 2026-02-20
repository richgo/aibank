# Flutter Client Specification Delta

## ADDED Requirements

### Requirement: Namespaced Component Registration

The system SHALL support registering catalog items with namespaced identifiers from MCP-App manifests.

#### Scenario: Register Namespaced Component

- GIVEN an MCP-App manifest declares a `MapView` component in namespace `googlemaps`
- WHEN the client registers the component
- THEN the component is stored with key `googlemaps:MapView`
- AND lookups for `googlemaps:MapView` return the registered component

#### Scenario: Namespace Does Not Affect Internal Components

- GIVEN internal banking catalog items are registered
- WHEN the catalog is queried for `AccountCard`
- THEN the component is found without namespace prefix
- AND no collision occurs with namespaced components

### Requirement: MCP-App Catalog Loading

The system SHALL load component catalogs from configured MCP-App manifests at startup.

#### Scenario: Load Google Maps Catalog

- GIVEN the app is configured with Google Maps MCP-App
- WHEN the app initializes
- THEN the `googlemaps:MapView` component is registered in the catalog
- AND the component is available for rendering in A2UI surfaces

#### Scenario: Multiple MCP-App Catalogs

- GIVEN multiple MCP-Apps are configured
- WHEN the app initializes
- THEN components from all MCP-Apps are registered
- AND each uses its respective namespace prefix

### Requirement: MapView Component Rendering

The system SHALL render the `googlemaps:MapView` component as an interactive map display.

#### Scenario: Render Map with Single Marker

- GIVEN the agent sends a surface with a `googlemaps:MapView` component
- WHEN the data model contains `latitude`, `longitude`, and `label`
- THEN a map widget renders centered on the coordinates
- AND a marker is displayed at the specified location
- AND the marker shows the label text

#### Scenario: Map Has Fixed Height

- GIVEN a `googlemaps:MapView` component is rendered
- WHEN displayed in the conversation
- THEN the map has a fixed height suitable for inline display (e.g., 200-300px)
- AND the map is not scrollable within the conversation scroll

## MODIFIED Requirements

### Requirement: GenUI Conversation Setup

The system SHALL initialize a `GenUiConversation` connected to the backend agent via `genui_a2ui`, with support for namespaced MCP-App components.

(Previously: Only registered internal banking catalog at startup.)

#### Scenario: App Launches with MCP-App Components

- GIVEN the app is started on a mobile device
- WHEN the main screen loads
- THEN a `GenUiConversation` is initialized with the backend agent URL
- AND the `A2uiMessageProcessor` is configured with banking catalog AND MCP-App catalogs
- AND namespaced components like `googlemaps:MapView` are resolvable
