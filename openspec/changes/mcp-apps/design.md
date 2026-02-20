# Design: MCP-Apps Support

## Overview

This design introduces a multi-MCP architecture where the backend agent connects to both the internal bank MCP server and the external Google Maps MCP server. Components from external MCP-Apps use namespaced identifiers (`googlemaps:MapView`) to prevent catalog collisions. The Flutter client registers MCP-App components alongside internal banking components, enabling rich map-based transaction location display.

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
| MCP-App Config | `agent/mcp_apps.py` | MCP-App manifest loading and multi-server orchestration |
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

**Rationale:** `flutter_map` is BSD-licensed, works cross-platform with minimal setup, and can use free OpenStreetMap tiles. The Google Maps MCP provides geocoding data; we don't need Google's map tiles for display. This keeps the POC simple and cost-free.

### Decision: MCP-App Component Registration

**Chosen:** Static registration at app startup via `buildMcpAppCatalogs()` function

**Alternatives considered:**
- Dynamic manifest fetching at runtime — rejected because it adds network latency at startup and requires error handling for unavailable MCP servers
- Code generation from manifest — rejected because it adds build-time complexity for a POC

**Rationale:** For this POC, MCP-Apps are known at build time. The `googlemaps:MapView` component is implemented in Dart and registered alongside banking components. Dynamic loading can be added later.

### Decision: Multi-MCP Orchestration Pattern

**Chosen:** Sequential orchestration in runtime — bank MCP first, then Google Maps MCP

**Alternatives considered:**
- Parallel calls — rejected because geocoding depends on transaction data (merchant name)
- LLM-driven orchestration — rejected because the deterministic runtime needs explicit flow

**Rationale:** The data flow is inherently sequential: get transaction → extract merchant → geocode. The runtime handles this explicitly with two `call_tool` invocations to different MCP backends.

### Decision: MCP Server Connection Model

**Chosen:** Direct HTTP calls to Google Maps MCP endpoint (not stdio)

**Alternatives considered:**
- stdio subprocess like bank MCP — rejected because Google Maps MCP is an external service, not locally hosted
- MCP client library — rejected because adds dependency for simple HTTP+JSON

**Rationale:** Google Maps MCP exposes HTTP endpoints. A lightweight `httpx` call with JSON payload is sufficient. The internal bank MCP continues using stdio via the existing `call_tool` function.

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
│  4. call_googlemaps_tool("geocode", query="Tesco Superstore")  │
│     → Google Maps MCP (HTTP)                                    │
│  5. Returns RuntimeResponse(                                    │
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
            "label": "Tesco Superstore"
        }
    }
)
```

## Dependencies

### Python (agent)

| Package | Version | Purpose |
|---------|---------|---------|
| `httpx` | ^0.27 | HTTP client for Google Maps MCP calls |

### Flutter (app)

| Package | Version | Purpose |
|---------|---------|---------|
| `flutter_map` | ^6.0.0 | Map widget rendering |
| `latlong2` | ^0.9.0 | Coordinate types for flutter_map |

## Migration / Backwards Compatibility

**Fully backwards compatible.**

- Existing A2UI templates continue to work unchanged
- Internal catalog items (`AccountCard`, `TransactionList`, etc.) are unaffected
- The new `transaction_location` intent only triggers on specific keywords
- Clients without the `googlemaps:MapView` component registered will fail gracefully (GenUI shows placeholder for unknown components)

## Testing Strategy

| Spec Requirement | Test Type | Approach |
|-----------------|-----------|----------|
| Namespace prefix parsing | Unit | Test `googlemaps:MapView` splits into namespace + name |
| Multi-MCP orchestration | Integration | Mock both MCP servers, verify sequential calls |
| Transaction location intent | Unit | Test `_intent()` with various "where" queries |
| MapView rendering | Widget | Verify FlutterMap renders with marker at given coords |
| Geocode failure handling | Unit | Mock geocode error, verify no MapView in response |
| Template validation | Unit | Validate `transaction_location.json` against A2UI schema |

### Test Files to Create

- `agent/tests/test_mcp_apps.py` — Multi-MCP orchestration tests
- `agent/tests/test_transaction_location_intent.py` — Intent detection tests
- `app/test/catalog/googlemaps/map_view_test.dart` — MapView widget tests
- `app/integration_test/transaction_location_test.dart` — E2E flow test

## Edge Cases

### Merchant Name Not Geocodable

**Scenario:** Transaction description is "Online Purchase" or "Direct Debit".

**Handling:**
1. Google Maps MCP returns empty results or error
2. Runtime returns a text-only response: "This transaction doesn't have a physical location."
3. No `transaction_location.json` template is used; falls back to standard transaction detail

### Multiple Matching Transactions

**Scenario:** User says "where was my Tesco transaction?" but has 3 Tesco transactions.

**Handling:**
1. Runtime selects the most recent matching transaction
2. Response text clarifies: "Here is where your most recent Tesco transaction occurred (Feb 14)."
3. Future enhancement: ask user to clarify which transaction

### Google Maps MCP Unavailable

**Scenario:** Network error or MCP server down.

**Handling:**
1. `call_googlemaps_tool()` raises exception
2. Runtime catches and returns fallback: "I couldn't load the map. Here are the transaction details."
3. Uses `transaction_list.json` template instead
4. No crash or hang in the agent

### Invalid Coordinates from Geocode

**Scenario:** Geocode returns malformed lat/lng (null, out of range).

**Handling:**
1. Runtime validates coordinates before including in response
2. If invalid, treat as geocode failure (see above)
3. Valid ranges: latitude -90 to 90, longitude -180 to 180
