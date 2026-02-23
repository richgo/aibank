# Google Maps Catalog Specification


### Requirement: MapView Component

The system SHALL provide a `googlemaps:MapView` catalog item that displays a map with a location marker.

#### Scenario: Render MapView with Coordinates

- GIVEN the agent sends a surface with a `googlemaps:MapView` component
- WHEN the data model contains `latitude` (number), `longitude` (number), and `label` (string)
- THEN a map widget renders centered on the specified coordinates
- AND a marker is placed at the latitude/longitude position
- AND the marker displays the label as an info window or tooltip

#### Scenario: MapView Data Schema

- GIVEN the `googlemaps:MapView` component schema
- WHEN validated against the A2UI component specification
- THEN the schema requires `latitude` (number), `longitude` (number)
- AND the schema optionally accepts `label` (string) and `zoom` (number)

#### Scenario: Default Zoom Level

- GIVEN a `googlemaps:MapView` component without explicit zoom
- WHEN the map renders
- THEN a default zoom level of 15 (street-level) is applied
- AND the merchant location is clearly visible

#### Scenario: MapView with Custom Zoom

- GIVEN a `googlemaps:MapView` component with `zoom: 12`
- WHEN the map renders
- THEN the map uses zoom level 12
- AND a wider area around the merchant is visible

### Requirement: MapView Styling

The system SHALL render the MapView with styling consistent with the banking app theme.

#### Scenario: Map Uses App Color Scheme

- GIVEN the banking app has a defined color scheme
- WHEN the `googlemaps:MapView` renders
- THEN the marker uses the app's primary color
- AND the map controls (if visible) do not clash with the app theme

#### Scenario: Map Is Non-Interactive for POC

- GIVEN the `googlemaps:MapView` is rendered inline in conversation
- WHEN the user views the map
- THEN the map displays the location statically
- AND pan/zoom gestures are disabled for this POC scope

### Requirement: Google Maps MCP Tool Integration

The system SHALL call the Google Maps MCP server to geocode merchant names.

#### Scenario: Geocode Merchant Name

- GIVEN a transaction with description "Tesco Superstore"
- WHEN the agent calls the `geocode` tool on Google Maps MCP
- THEN the tool returns latitude and longitude for a Tesco location
- AND the coordinates are suitable for display in MapView

#### Scenario: Geocode Returns Multiple Results

- GIVEN a merchant name that matches multiple locations
- WHEN the agent calls the `geocode` tool
- THEN the tool returns the most relevant result (first match)
- AND the agent uses this result for the MapView

#### Scenario: Geocode Fails

- GIVEN a merchant name that cannot be geocoded (e.g., "Online Purchase")
- WHEN the agent calls the `geocode` tool
- THEN the tool returns an error or empty result
- AND the agent responds with text indicating location is unavailable
- AND no MapView component is rendered
