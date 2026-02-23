# Tasks: MCP-Apps Support

## Phase 1: Dependencies & Configuration

- [x] **1.1** Add Python dependencies for map server MCP client
  Add `httpx` to `agent/requirements.txt` (or `pyproject.toml`). This enables HTTP calls to the map server MCP endpoint.
  *Covers: design decision on MCP server connection model*

- [x] **1.2** Add Flutter dependencies for map rendering
  Add `flutter_map: ^6.0.0` and `latlong2: ^0.9.0` to `app/pubspec.yaml`. Run `flutter pub get`.
  *Covers: design decision on map library*

- [x] **1.3** Create MCP-Apps configuration module
  Create `agent/mcp_apps.py` with configuration dataclass for MCP-App endpoints. Read `MAP_SERVER_URL` environment variable. Default to disabled if not set. No API key needed — the map server uses free OpenStreetMap/Nominatim.
  *Covers: mcp-apps-protocol spec — MCP-App Configuration requirement*

## Phase 2: Backend Agent — Multi-MCP & Intent

- [x] **2.1** Implement map server MCP client function
  In `agent/mcp_apps.py`, add `call_map_server_tool(tool_name: str, **kwargs)` that sends a MCP JSON-RPC `tools/call` request via HTTP POST to `MAP_SERVER_URL`. Parse `result.content` from the JSON-RPC response. Return `None` on any failure (connection error, HTTP error, missing content).
  *Covers: backend-agent spec — Multi-MCP Server Orchestration*

- [x] **2.2** Add `geocode` tool wrapper
  In `agent/mcp_apps.py`, add `geocode_merchant(query: str) -> dict | None` that calls `call_map_server_tool("geocode", query=query)` and parses the Nominatim result from the MCP text content item. Extract lat/lon from `lat`/`lon` string fields, or compute centroid from `boundingbox` (`[south, north, west, east]`). Use `display_name` as label. Validate coordinate ranges (-90 to 90, -180 to 180).
  *Covers: googlemaps-catalog spec — Geocode Merchant Name scenario*

- [x] **2.3** Add transaction location intent detection
  In `agent/runtime.py`, update `DeterministicRuntime._intent()` to detect `transaction_location` intent when message contains "where", "location", "map", or "show me" combined with transaction context.
  *Covers: backend-agent spec — Transaction Location Intent, Location Intent Keywords scenario*

- [x] **2.4** Extract merchant name from user query
  In `agent/runtime.py`, add `_extract_merchant(message: str, transactions: list) -> tuple[dict, str] | None` that finds the most recent transaction matching a merchant mentioned in the query. Return the transaction and merchant name.
  *Covers: design edge case — Multiple Matching Transactions*

- [x] **2.5** Implement transaction location flow in runtime
  In `agent/runtime.py`, add handling for `transaction_location` intent: call `get_transactions`, extract merchant, call `geocode_merchant`, construct response with location data. Fall back to text response if geocode fails.
  *Covers: backend-agent spec — Cross-MCP Tool Orchestration, Agent Generates Map Surface*

- [x] **2.6** Create transaction location A2UI template
  Create `agent/templates/transaction_location.json` with Column containing transaction Text and `googlemaps:MapView` component. Bind to `/transaction/*` and `/location/*` data paths.
  *Covers: backend-agent spec — Transaction Location Template Structure scenario*

- [x] **2.7** Add transaction_location template to allowed list
  In `agent/runtime.py`, add `"transaction_location.json"` to the `allowed` template set in `ADKRuntime.run()`.
  *Covers: template validation*

- [x] **2.8** Update agent card with Google Maps catalog
  In `agent/agent.py`, update `a2a_agent_card()` to include `"https://aibank.local/catalogs/googlemaps-v1.json"` in `supportedCatalogIds`.
  *Covers: design — Agent Card Extension*

## Phase 3: Flutter Client — MapView Component

- [x] **3.1** Create googlemaps catalog directory structure
  Create `app/lib/catalog/googlemaps/` directory for MCP-App components.

- [x] **3.2** Implement MapView catalog item
  Create `app/lib/catalog/googlemaps/map_view.dart` with `mapViewItem()` function returning `CatalogItem`. Name: `googlemaps:MapView`. Schema: `latitude` (number, required), `longitude` (number, required), `label` (string, optional), `zoom` (number, optional, default 15).
  *Covers: googlemaps-catalog spec — MapView Component, MapView Data Schema*

- [x] **3.3** Implement MapView widget with FlutterMap
  In `map_view.dart`, implement widget using `FlutterMap` with OpenStreetMap tile layer. Center on lat/lng, place marker at coordinates, show label in marker tooltip. Fixed height 250px, disable gestures for POC.
  *Covers: googlemaps-catalog spec — Render MapView with Coordinates, Default Zoom Level, Map Is Non-Interactive*

- [x] **3.4** Style MapView marker with app theme
  Use `BankTheme.primaryColor` for marker color. Ensure visual consistency with banking app.
  *Covers: googlemaps-catalog spec — MapView Styling, Map Uses App Color Scheme*

- [x] **3.5** Create MCP-App catalog builder
  Create `app/lib/catalog/googlemaps/googlemaps_catalog.dart` with `buildGoogleMapsCatalog()` function that returns a `Catalog` containing `mapViewItem()`.

- [x] **3.6** Register MCP-App catalog in banking catalogs
  Update `app/lib/catalog/banking_catalog.dart` to import `googlemaps_catalog.dart` and include `buildGoogleMapsCatalog()` in the returned catalog list.
  *Covers: flutter-client spec — MCP-App Catalog Loading, App Launches with MCP-App Components*

## Phase 4: Testing

- [x] **4.1** Write unit tests for geocode_merchant
  Update `agent/test_mcp_apps.py`. Test: successful geocode with string lat/lon fields, bounding box centroid fallback, geocode failure (empty result), invalid coordinates rejection, network error handling.
  *Covers: googlemaps-catalog spec — Geocode Fails scenario; Nominatim response format*

- [x] **4.2** Write unit tests for transaction location intent
  Create `agent/test_transaction_location.py`. Test intent detection for "where was my Tesco purchase?", "show me on a map", "location of transaction". Verify non-location queries don't trigger intent.
  *Covers: backend-agent spec — Location Intent Keywords scenario*

- [x] **4.3** Write unit tests for merchant extraction
  In `test_transaction_location.py`, test `_extract_merchant` finds correct transaction, handles multiple matches (returns most recent), handles no matches.

- [x] **4.4** Write widget tests for MapView
  Create `app/test/catalog/googlemaps/map_view_test.dart`. Test MapView renders with valid coordinates, shows marker, displays label. Test default zoom level 15 and custom zoom.
  *Covers: googlemaps-catalog spec — Render MapView with Coordinates, Default Zoom Level, MapView with Custom Zoom*

- [x] **4.5** Write integration test for transaction location flow
  Create `app/integration_test/transaction_location_test.dart`. Mock agent response with `googlemaps:MapView` component, verify map surface appears in conversation.
  *Covers: flutter-client spec — Render Map with Single Marker*

- [x] **4.6** Validate transaction_location.json template
  Add test in `agent/test_templates.py` that validates `transaction_location.json` against `A2UI_SCHEMA`.
  *Covers: backend-agent spec — surface is valid A2UI v0.8*

## Phase 5: Verification

- [x] **5.1** Start map server and wire up dev environment
  1. `dev.sh` updated — starts `@modelcontextprotocol/server-map` on port 3001 before the agent
  2. `MAP_SERVER_URL=http://localhost:3001/mcp` exported in `dev.sh` before agent starts
  3. `agent/.env.example` updated with commented `MAP_SERVER_URL` entry
  4. `call_map_server_tool` verified: sends MCP JSON-RPC (`tools/call`), parses SSE `data:` line
  5. Live test confirmed: `geocode_merchant("Tesco Superstore London")` → `{latitude: 51.459007, longitude: -0.337418, label: "Tesco Extra, Isleworth, London"}`
  *Discovery: map server requires `Accept: application/json, text/event-stream` (406 without it) and always returns SSE. Geocode result is formatted text, not JSON — `mcp_apps.py` updated with SSE parser and regex coordinate extractor.*

- [x] **5.2** End-to-end verification via agent API
  1. `POST /chat` → `"show my transactions"` → `transaction_list.json` template returned ✓
  2. `POST /chat` → `selectTransaction` action with `{description: "Tesco Superstore"}` →
     - `text`: "Here is where your Tesco Superstore transaction occurred."
     - `a2ui` surface contains `googlemaps:MapView` component with lat/lon data bindings ✓
     - `data.location`: `{latitude: 51.726783, longitude: -1.202892, label: "Tesco Superstore, Oxford Retail Park, Oxford"}` ✓

- [x] **5.3** Fallback behavior verified
  1. Agent restarted without `MAP_SERVER_URL`
  2. `selectTransaction` action → response has no `googlemaps:MapView` component ✓
  3. Fallback surface uses `transaction_list.json` components (`txRow`, `txRowButton`, etc.) ✓
  4. No crash — response returned cleanly ✓

- [x] **5.4** Non-geocodable merchant — findings
  Nominatim (used by map server) geocodes almost every query, including online-only merchants:
  - "Spotify" → Spotify Camp Nou, Barcelona (OSM POI, unrelated to UK subscription)
  - True "no results" from Nominatim is rare for named merchants
  The fallback path (`geocode_merchant` returns `None`) is triggered only by:
  - Map server unavailable / `MAP_SERVER_URL` unset (verified in 5.3)
  - Network timeout or HTTP error
  This path is covered by unit tests in `test_transaction_location.py` (mock geocode returning `None`).
  *Future work: add a merchant classification step to reject clearly non-physical results (e.g., "Spotify", "Council Tax", "Amazon UK") before calling geocode.*
