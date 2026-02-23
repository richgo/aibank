# Flutter Client Specification Delta


### Requirement: GenUI Conversation Setup

The system SHALL initialize a `GenUiConversation` connected to the backend agent via `genui_a2ui`, with support for namespaced MCP-App components.

#### Scenario: App Launches and Connects to Agent

- GIVEN the app is started on a mobile device
- WHEN the main screen loads
- THEN a `GenUiConversation` is initialized with the backend agent URL
- AND the `A2uiMessageProcessor` is configured with the banking widget catalog

#### Scenario: App Launches with MCP-App Components

- GIVEN the app is started on a mobile device
- WHEN the main screen loads
- THEN a `GenUiConversation` is initialized with the backend agent URL
- AND the `A2uiMessageProcessor` is configured with banking catalog AND MCP-App catalogs
- AND namespaced components like `googlemaps:MapView` are resolvable

### Requirement: Chat-Based Interaction

The system SHALL provide a text input field for the user to send natural language banking queries to the agent.

#### Scenario: User Sends a Query

- GIVEN the user is on the main screen
- WHEN the user types "show my accounts" and taps send
- THEN the message is sent to the agent via `GenUiConversation.sendRequest()`
- AND a loading indicator is displayed while awaiting the response

#### Scenario: Agent Responds with A2UI Surface

- GIVEN the user has sent a query
- WHEN the agent responds with A2UI messages
- THEN a `GenUiSurface` renders the agent-generated UI inline in the conversation
- AND any text response is displayed as a chat message

### Requirement: Surface Lifecycle Management

The system SHALL track active A2UI surfaces and display them as they are added or removed by the agent.

#### Scenario: New Surface Added

- GIVEN the agent generates a new surface
- WHEN the `onSurfaceAdded` callback fires with a surface ID
- THEN a `GenUiSurface` widget is added to the conversation view for that surface ID

#### Scenario: Surface Deleted

- GIVEN an active surface exists in the conversation
- WHEN the agent sends a `deleteSurface` message
- THEN the corresponding `GenUiSurface` widget is removed from the view

### Requirement: Mobile-Only Layout

The system SHALL target iOS and Android only, using a single-column mobile layout.

#### Scenario: App Renders on Mobile

- GIVEN the app is built for iOS or Android
- WHEN the user opens the app
- THEN the layout is a single-column scrollable view with chat input at the bottom
- AND no responsive breakpoints for web or desktop are applied

### Requirement: User Action Forwarding

The system SHALL forward user interactions on A2UI components (button taps, form submissions) back to the agent.

#### Scenario: User Taps a Button in Generated UI

- GIVEN the agent has rendered a surface with a Button component
- WHEN the user taps the button
- THEN a `userAction` event is sent to the agent with the action name and current data model state
- AND the agent processes the action and may respond with updated surfaces

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
