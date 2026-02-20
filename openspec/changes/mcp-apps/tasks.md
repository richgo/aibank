# Tasks: MCP-Apps Support

## Phase 1: Dependencies & Configuration

- [x] **1.1** Add Python dependencies for Google Maps MCP client
  Add `httpx` to `agent/requirements.txt` (or `pyproject.toml`). This enables HTTP calls to the Google Maps MCP server.
  *Covers: design decision on MCP server connection model*

- [x] **1.2** Add Flutter dependencies for map rendering
  Add `flutter_map: ^6.0.0` and `latlong2: ^0.9.0` to `app/pubspec.yaml`. Run `flutter pub get`.
  *Covers: design decision on map library*

- [x] **1.3** Create MCP-Apps configuration module
  Create `agent/mcp_apps.py` with configuration dataclass for MCP-App endpoints. Include `GOOGLE_MAPS_MCP_URL` and `GOOGLE_MAPS_API_KEY` environment variable loading. Default to disabled if not configured.
  *Covers: mcp-apps-protocol spec — MCP-App Configuration requirement*

## Phase 2: Backend Agent — Multi-MCP & Intent

- [x] **2.1** Implement Google Maps MCP client function
  In `agent/mcp_apps.py`, add `call_googlemaps_tool(tool_name: str, **kwargs)` function that makes HTTP POST to Google Maps MCP endpoint. Handle connection errors gracefully, returning `None` on failure.
  *Covers: backend-agent spec — Multi-MCP Server Orchestration*

- [x] **2.2** Add `geocode` tool wrapper
  In `agent/mcp_apps.py`, add `geocode_merchant(query: str) -> dict | None` that calls `call_googlemaps_tool("geocode", query=query)` and extracts lat/lng from response. Validate coordinates are in valid ranges (-90 to 90, -180 to 180).
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
  Create `agent/tests/test_mcp_apps.py`. Test successful geocode, geocode failure (empty result), invalid coordinates rejection, network error handling.
  *Covers: googlemaps-catalog spec — Geocode Fails scenario*

- [x] **4.2** Write unit tests for transaction location intent
  Create `agent/tests/test_transaction_location_intent.py`. Test intent detection for "where was my Tesco purchase?", "show me on a map", "location of transaction". Verify non-location queries don't trigger intent.
  *Covers: backend-agent spec — Location Intent Keywords scenario*

- [x] **4.3** Write unit tests for merchant extraction
  In `test_transaction_location_intent.py`, test `_extract_merchant` finds correct transaction, handles multiple matches (returns most recent), handles no matches.

- [x] **4.4** Write widget tests for MapView
  Create `app/test/catalog/googlemaps/map_view_test.dart`. Test MapView renders with valid coordinates, shows marker, displays label. Test default zoom level 15 and custom zoom.
  *Covers: googlemaps-catalog spec — Render MapView with Coordinates, Default Zoom Level, MapView with Custom Zoom*

- [x] **4.5** Write integration test for transaction location flow
  Create `app/integration_test/transaction_location_test.dart`. Mock agent response with `googlemaps:MapView` component, verify map surface appears in conversation.
  *Covers: flutter-client spec — Render Map with Single Marker*

- [x] **4.6** Validate transaction_location.json template
  Add test in `agent/tests/test_templates.py` (or create if needed) that validates `transaction_location.json` against `A2UI_SCHEMA`.
  *Covers: backend-agent spec — surface is valid A2UI v0.8*

## Phase 5: Verification

- [x] **5.1** Manual end-to-end verification
  1. Start agent with `GOOGLE_MAPS_MCP_URL` configured (or mock endpoint)
  2. Start Flutter app
  3. Send "show my transactions"
  4. Send "where was my Tesco transaction?"
  5. Verify map surface appears with marker at geocoded location
  6. Verify transaction details display above map

- [x] **5.2** Verify fallback behavior
  1. Disable Google Maps MCP (unset env var or point to invalid URL)
  2. Send "where was my transaction?"
  3. Verify text fallback: "I couldn't load the map" or similar
  4. Verify no crash or hang

- [x] **5.3** Verify non-geocodable merchant handling
  1. Ensure transaction list includes "Online Purchase" or similar
  2. Send "where was my online purchase?"
  3. Verify response indicates no physical location
  4. Verify no MapView component rendered
