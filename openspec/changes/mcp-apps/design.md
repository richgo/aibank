# Design: MCP-Apps Support

## Overview

This design introduces a multi-MCP architecture where the backend agent connects to both the internal bank MCP server and the external map server (`@modelcontextprotocol/server-map`). Components from external MCP-Apps use namespaced identifiers (`googlemaps:MapView`) to prevent catalog collisions. The Flutter client registers MCP-App components alongside internal banking components, enabling rich map-based transaction location display.

## Architecture

### Components Affected

| Component | File(s) | Changes |
|-----------|---------|---------|
| Agent Runtime | `agent/runtime.py` | Add `transaction_location` intent, multi-MCP tool dispatch |
| Agent Server | `agent/agent.py` | Add `transaction_location.json` template, update agent card |
| Banking Catalog | `app/lib/catalog/banking_catalog.dart` | Register MCP-App catalogs with namespace support |
| Chat Screen | `app/lib/screens/chat_screen.dart` | No changes (catalogs loaded at init) |

### New Components

| Component | File(s) | Purpose |
|-----------|---------|---------|
| MCP-App Config | `agent/mcp_apps.py` | Map server connection config and multi-server orchestration |
| Google Maps Catalog | `app/lib/catalog/googlemaps/map_view.dart` | `googlemaps:MapView` component implementation |
| Transaction Location Template | `agent/templates/transaction_location.json` | A2UI template for map + transaction detail |

## Technical Decisions

### Decision: Namespace Separator Character

**Chosen:** Colon (`:`) — e.g., `googlemaps:MapView`

**Alternatives considered:**
- Slash (`/`) — rejected because it conflicts with JSON path syntax used in data bindings
- Double underscore (`__`) — rejected because it's verbose and uncommon in component naming
- Dot (`.`) — rejected because it could be confused with package imports

**Rationale:** Colon is widely used for namespace separation (XML namespaces, Kubernetes labels, CSS pseudo-elements). It's visually distinct and doesn't conflict with existing A2UI syntax.

### Decision: Map Library for Flutter

**Chosen:** `flutter_map` with OpenStreetMap tiles

**Alternatives considered:**
- `google_maps_flutter` — rejected because it requires separate API key management, platform-specific setup (Android API key in manifest, iOS in Info.plist), and has stricter usage terms
- `mapbox_gl` — rejected because it requires Mapbox access token and has usage-based pricing

**Rationale:** `flutter_map` is BSD-licensed, works cross-platform with minimal setup, and can use free OpenStreetMap tiles. The map server provides geocoding data; we don't need proprietary map tiles for display. This keeps the POC simple and cost-free.

### Decision: Map Rendering Approach

**Chosen:** Call only the `geocode` tool; render the map natively in Flutter using `flutter_map`

**Alternatives considered:**
- Use the `show-map` tool + CesiumJS HTML UI (`ui://cesium-map/mcp-app.html`) — rejected because it requires embedding a WebView/iframe, adds cross-origin complexity, and breaks visual consistency with the native Flutter UI
- Hybrid (geocode for coordinates, show-map for display) — rejected because the CesiumJS globe is overkill for a single-marker POC and WebView adds platform-specific configuration

**Rationale:** The map server exposes two tools: `geocode` (Nominatim search, returns results with lat/lon and bounding boxes) and `show-map` (drives a 3D CesiumJS globe via the server's own MCP App HTML UI). We use only `geocode` to obtain coordinates and render the result ourselves. This keeps map rendering in-process, allows theming with `BankTheme`, and avoids the complexity of the MCP App HTML UI pattern.

### Decision: MCP-App Component Registration

**Chosen:** Static registration at app startup via `buildMcpAppCatalogs()` function

**Alternatives considered:**
- Dynamic manifest fetching at runtime — rejected because it adds network latency at startup and requires error handling for unavailable MCP servers
- Code generation from manifest — rejected because it adds build-time complexity for a POC

**Rationale:** For this POC, MCP-Apps are known at build time. The `googlemaps:MapView` component is implemented in Dart and registered alongside banking components. Dynamic loading can be added later.

### Decision: Multi-MCP Orchestration Pattern

**Chosen:** Sequential orchestration in runtime — bank MCP first, then map server MCP

**Alternatives considered:**
- Parallel calls — rejected because geocoding depends on transaction data (merchant name)
- LLM-driven orchestration — rejected because the deterministic runtime needs explicit flow

**Rationale:** The data flow is inherently sequential: get transaction → extract merchant → geocode. The runtime handles this explicitly with two `call_tool` invocations to different MCP backends.

### Decision: MCP Server Connection Model

**Chosen:** Direct HTTP calls to map server MCP endpoint using MCP JSON-RPC protocol

**Alternatives considered:**
- stdio subprocess like bank MCP — rejected because the map server is a separate npm process, not a Python module
- MCP client library — rejected because it adds a dependency for a straightforward HTTP+JSON-RPC call

**Rationale:** The map server exposes a Streamable HTTP transport at `/mcp` (port 3001). We POST standard MCP JSON-RPC (`tools/call` method) and parse the `result.content` array. The internal bank MCP continues using stdio via the existing `call_tool` function.

## Data Flow

```
User: "Where was my Tesco transaction?"
         │
         ▼
┌─────────────────────────────────────────────────────────────────┐
│ Agent Runtime (runtime.py)                                      │
│                                                                 │
│  1. _intent() detects "transaction_location"                    │
│  2. call_tool("get_transactions") → bank MCP (stdio)           │
│  3. Filter transactions matching "Tesco"                        │
│  4. call_map_server_tool("geocode", query="Tesco Superstore")  │
│     → map server MCP (HTTP POST /mcp, JSON-RPC tools/call)     │
│  5. Parse Nominatim result: extract lat/lon or bbox centroid    │
│  6. Returns RuntimeResponse(                                    │
│       template_name="transaction_location.json",                │
│       data={transaction: {...}, location: {lat, lng, label}}   │
│     )                                                           │
└─────────────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────────┐
│ Agent Server (agent.py)                                         │
│                                                                 │
│  1. Load transaction_location.json template                     │
│  2. Inject data into dataModelUpdate                            │
│  3. Return A2UI messages with googlemaps:MapView component     │
└─────────────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────────┐
│ Flutter Client                                                  │
│                                                                 │
│  1. A2uiMessageProcessor receives surfaceUpdate                 │
│  2. Component lookup: "googlemaps:MapView" → registered item   │
│  3. widgetBuilder() creates FlutterMap widget                   │
│  4. Marker placed at lat/lng with label                         │
└─────────────────────────────────────────────────────────────────┘
```

## API Changes

### Agent Card Extension

The agent card at `/.well-known/agent-card.json` adds the Google Maps catalog to `supportedCatalogIds`:

```json
{
  "capabilities": {
    "extensions": [{
      "uri": "https://a2ui.org/a2a-extension/a2ui/v0.8",
      "params": {
        "supportedCatalogIds": [
          "https://a2ui.org/specification/v0_8/standard_catalog_definition.json",
          "https://aibank.local/catalogs/banking-v1.json",
          "https://aibank.local/catalogs/googlemaps-v1.json"
        ]
      }
    }]
  }
}
```

### New A2UI Template: `transaction_location.json`

```json
[
  {
    "surfaceUpdate": {
      "surfaceId": "main_surface",
      "components": [
        {"id": "root", "component": {"Column": {"children": {"explicitList": ["txdetail", "map"]}}}},
        {"id": "txdetail", "component": {"Text": {"text": {"path": "/transaction/description"}}}},
        {"id": "map", "component": {"googlemaps:MapView": {
          "latitude": {"path": "/location/latitude"},
          "longitude": {"path": "/location/longitude"},
          "label": {"path": "/location/label"},
          "zoom": 15
        }}}
      ]
    }
  },
  {"dataModelUpdate": {"surfaceId": "main_surface", "contents": []}},
  {"beginRendering": {"surfaceId": "main_surface", "root": "root"}}
]
```

### Map Server Wire Protocol

Tool calls use MCP JSON-RPC over HTTP POST to `MAP_SERVER_URL` (default: `http://localhost:3001/mcp`):

```
POST http://localhost:3001/mcp
Content-Type: application/json
Accept: application/json, text/event-stream   ← BOTH required; server returns 406 otherwise

{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "tools/call",
  "params": {
    "name": "geocode",
    "arguments": {"query": "Tesco Superstore"}
  }
}
```

Response (always SSE format — `event:` / `data:` lines):
```
event: message
data: {"result":{"content":[{"type":"text","text":"1. Tesco Extra, Mogden Lane, Isleworth, TW7 7JY\n   Coordinates: 51.459007, -0.337418\n   Bounding box: W:-0.3384, S:51.4585, E:-0.3367, N:51.4597\n\n2. ..."}]},"jsonrpc":"2.0","id":1}
```

Key wire-format properties (verified against live server):
- The `Accept` header **must** include both `application/json` **and** `text/event-stream` — the server returns HTTP 406 with `application/json` alone
- The server **always** returns SSE format (`event: message\ndata: <json>`), never plain JSON
- The `geocode` tool returns **human-readable formatted text**, not a JSON array. Each result is:
  ```
  1. Place Name, Address
     Coordinates: lat, lon
     Bounding box: W:x, S:y, E:z, N:w
  ```
- We extract the first result's coordinates using a regex: `Coordinates:\s*([-\d.]+),\s*([-\d.]+)`
- The first line of each result (after the number) is used as the map marker label

### Runtime Data Contract

```python
RuntimeResponse(
    text="Here is where your Tesco transaction occurred.",
    template_name="transaction_location.json",
    data={
        "transaction": {
            "id": "tx_acc_current_001_003",
            "date": "2026-02-14",
            "description": "Tesco Superstore",
            "amount": "45.32",
            "type": "debit"
        },
        "location": {
            "latitude": 51.5074,
            "longitude": -0.1278,
            "label": "Tesco, London, UK"
        }
    }
)
```

## Dependencies

### Python (agent)

| Package | Version | Purpose |
|---------|---------|---------|
| `httpx` | ^0.27 | HTTP client for map server MCP calls |

### Flutter (app)

| Package | Version | Purpose |
|---------|---------|---------|
| `flutter_map` | ^6.0.0 | Map widget rendering |
| `latlong2` | ^0.9.0 | Coordinate types for flutter_map |

### Map server (dev / deployment)

| Requirement | Detail |
|-------------|--------|
| Node.js / npx | To run `@modelcontextprotocol/server-map` |
| No API key | Uses free OpenStreetMap / Nominatim — rate-limited to 1 req/sec |
| `MAP_SERVER_URL` env var | Set to `http://localhost:3001/mcp` in development |

## Migration / Backwards Compatibility

**Fully backwards compatible.**

- Existing A2UI templates continue to work unchanged
- Internal catalog items (`AccountCard`, `TransactionList`, etc.) are unaffected
- The new `transaction_location` intent only triggers on specific keywords
- Clients without the `googlemaps:MapView` component registered will fail gracefully (GenUI shows placeholder for unknown components)
- If `MAP_SERVER_URL` is unset, `geocode_merchant()` returns `None` and the runtime falls back to the standard transaction list view

## Testing Strategy

| Spec Requirement | Test Type | Approach |
|-----------------|-----------|----------|
| Namespace prefix parsing | Unit | Test `googlemaps:MapView` splits into namespace + name |
| Multi-MCP orchestration | Integration | Mock both MCP servers, verify sequential calls |
| Transaction location intent | Unit | Test `_intent()` with various "where" queries |
| MapView rendering | Widget | Verify FlutterMap renders with marker at given coords |
| Geocode failure handling | Unit | Mock geocode error, verify no MapView in response |
| Template validation | Unit | Validate `transaction_location.json` against A2UI schema |
| Nominatim bbox centroid | Unit | Verify centroid computed correctly from bounding box |

### Test Files to Create

- `agent/test_mcp_apps.py` — Multi-MCP orchestration and geocode parsing tests
- `agent/test_transaction_location.py` — Intent detection and runtime flow tests
- `app/test/catalog/googlemaps/map_view_test.dart` — MapView widget tests
- `app/integration_test/transaction_location_test.dart` — E2E flow test

## Edge Cases

### Merchant Name Not Geocodable

**Scenario:** Transaction description is "Online Purchase" or "Direct Debit".

**Handling:**
1. Map server returns empty results or error
2. Runtime returns a text-only response: "This transaction doesn't have a physical location."
3. No `transaction_location.json` template is used; falls back to standard transaction detail

### Multiple Matching Transactions

**Scenario:** User says "where was my Tesco transaction?" but has 3 Tesco transactions.

**Handling:**
1. Runtime selects the most recent matching transaction
2. Response text clarifies: "Here is where your most recent Tesco transaction occurred (Feb 14)."
3. Future enhancement: ask user to clarify which transaction

### Map Server MCP Unavailable

**Scenario:** Network error, map server not started, or `MAP_SERVER_URL` not set.

**Handling:**
1. `call_map_server_tool()` returns `None` (catches all exceptions)
2. Runtime catches and returns fallback: "I couldn't load the map. Here are the transaction details."
3. Uses `transaction_list.json` template instead
4. No crash or hang in the agent

### Invalid Coordinates from Geocode

**Scenario:** Geocode returns malformed lat/lng (null, out of range, non-numeric).

**Handling:**
1. Runtime validates coordinates before including in response
2. If invalid, treat as geocode failure (see above)
3. Valid ranges: latitude -90 to 90, longitude -180 to 180
