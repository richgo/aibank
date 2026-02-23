# Proposal: MCP-Apps Support

## Intent

The AIBank agent currently operates as a closed system: all UI components are defined internally in the banking catalog, and all MCP tools are hosted by a single local server. Users cannot benefit from the growing ecosystem of third-party MCP servers that provide specialized capabilities such as maps, weather, search, or payments.

When a customer views a transaction like "Tesco Superstore - £45.32", they see only text. There is no visual context—no map showing the merchant location, no way to verify where a charge originated. For financial transparency and fraud detection, location context matters.

The problem is twofold:
1. **No external MCP integration**: The agent cannot connect to third-party MCP servers to enrich data or provide new capabilities.
2. **No UI extensibility**: Third-party MCP apps cannot contribute UI components; they can only return text/data that the agent must manually map to existing catalog items.

This limits what the banking assistant can offer and creates a maintenance burden: every new visual capability requires internal catalog development rather than leveraging ecosystem components.

## Scope

### In Scope

- Define an MCP-App protocol layer that overlays onto A2UI v0.8
- Enable third-party MCP servers to declare UI component schemas they can render
- Integrate **`@modelcontextprotocol/server-map`** as the first external MCP app
- Add a `MapView` component to the A2UI catalog for displaying transaction locations
- Enrich transaction data with geocoded merchant locations via the map server's `geocode` tool
- Support displaying a map for a single transaction when the user requests location context

### Out of Scope

- Generic MCP app marketplace or discovery mechanism
- Runtime installation of MCP apps (apps are configured at deployment)
- Custom theming or styling of third-party components
- Map interactions beyond display (no routing, directions, or street view)
- Bulk geocoding of historical transactions
- Real-time location tracking or user geolocation

## Approach

Introduce an **MCP-App manifest** that third-party MCP servers can expose, declaring:
- Available tools (standard MCP tool discovery)
- A2UI component schemas they provide (extension to MCP)
- Data transformations from tool output to component props

Components from MCP-Apps use **namespaced identifiers** to avoid collisions with internal catalog items. For example, map components are prefixed as `googlemaps:MapView`, while internal banking components remain unprefixed (`AccountCard`, `TransactionList`).

The backend agent orchestrates calls to multiple MCP servers. When a tool returns data that includes a component reference, the agent includes that namespaced component in the A2UI surface. The Flutter client registers component schemas from MCP-App manifests, keyed by their namespaced names.

For the initial implementation with the map server:
- The agent calls `get_transactions` on the bank MCP server
- When the user asks "where was this transaction?", the agent calls `geocode` on the map server with the merchant name
- The agent constructs a surface containing a `googlemaps:MapView` component with the returned coordinates
- The Flutter client renders the map using the component schema registered under the `googlemaps:` namespace

### MCP App HTML UI pattern (not used in this implementation)

The `@modelcontextprotocol/server-map` server also exposes a `ui://cesium-map/mcp-app.html` resource — a full web-based 3D globe rendered in CesiumJS. This represents a different MCP App pattern where the server provides its own rendered UI rather than data schemas for native components.

This implementation does **not** use the HTML UI pattern. Instead, we call only the `geocode` tool to obtain coordinates, then render the map natively in Flutter using `flutter_map`. This keeps the map in-process, avoids WebView/iframe embedding, and allows consistent theming with the banking app. The `show-map` tool (which drives the CesiumJS UI) is also not used for the same reasons.

## Impact

### Backend Agent (`agent/`)
- Must support multiple MCP server connections (currently single server)
- Runtime needs to orchestrate cross-MCP tool calls
- A2UI template generation must support components from external manifests

### MCP Server (`mcp_server/`)
- Transaction data structure gains optional `location` field for merchant coordinates
- May cache geocoded locations to avoid repeated API calls

### Flutter Client (`app/`)
- `A2uiMessageProcessor` must accept runtime component registration
- New `MapView` catalog item (or dynamic component loader)
- Dependency on mapping library (`flutter_map` with OpenStreetMap tiles)

### A2UI Protocol
- Extension to component schema for externally-defined components
- Possible `componentSource` field indicating the originating MCP app

### Configuration
- Map server endpoint becomes deployment configuration via `MAP_SERVER_URL`
- No API key required — the map server uses free OpenStreetMap/Nominatim services

## Risks

1. **Latency**: Chaining MCP calls (bank data → geocode → render) adds round-trips; user-perceived latency may increase.

2. **Data quality**: Merchant names in transaction data may not geocode accurately ("TFL" → multiple Transport for London locations; "Amazon UK" → no physical location).

3. **Security surface**: Connecting to external MCP servers introduces trust dependencies; malicious or compromised servers could inject harmful component schemas.

4. **Catalog conflicts**: External component names may collide with internal catalog items; namespace management needed.

5. **Offline degradation**: If external MCP server is unavailable, the feature should degrade gracefully rather than block core banking functions.

## Decisions

1. **Component namespace strategy**: MCP-App components use namespaced identifiers prefixed with the app name (e.g., `googlemaps:MapView`). Internal catalog items remain unprefixed.

2. **MCP-App selection**: `@modelcontextprotocol/server-map` (from the official `modelcontextprotocol/ext-apps` repository) is the integration target. It requires no API keys and uses OpenStreetMap/Nominatim for geocoding.
