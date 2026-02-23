"""
BDD-style scenario tests for MCP-Apps Protocol spec.
Each test corresponds to a Given/When/Then scenario from specs/mcp-apps-protocol/spec.md

Wire protocol:
  - map-server always returns SSE format: "event: message\ndata: <json>"
  - geocode tool returns human-readable text: "1. Name\n   Coordinates: lat, lon\n   ..."
  - Accept header must include both application/json AND text/event-stream
"""
import json
import os
from unittest.mock import patch, MagicMock
import pytest


# =============================================================================
# Helpers
# =============================================================================

def _sse_response(content: list) -> str:
    """Build an SSE response body as returned by the map server."""
    data = {"result": {"content": content, "isError": False}, "jsonrpc": "2.0", "id": 1}
    return f"event: message\ndata: {json.dumps(data)}\n\n"


def _geocode_text(lat: str = "51.5074", lon: str = "-0.1278", name: str = "London, UK") -> str:
    """Build formatted geocode text as returned by the map server."""
    return (
        f"1. {name}\n"
        f"   Coordinates: {lat}, {lon}\n"
        f"   Bounding box: W:-0.5, S:51.0, E:0.5, N:52.0"
    )


def _geocode_content(lat: str = "51.5074", lon: str = "-0.1278", name: str = "London, UK") -> list:
    """Build a MCP content list with geocode text as returned by the map server."""
    return [{"type": "text", "text": _geocode_text(lat, lon, name)}]


def _mock_http_response(content: list) -> MagicMock:
    """Build a mock httpx response that returns SSE body."""
    mock_response = MagicMock()
    mock_response.status_code = 200
    mock_response.text = _sse_response(content)
    return mock_response


# =============================================================================
# Requirement: MCP-App Configuration
# =============================================================================

def test_map_server_mcp_app_configured():
    """
    Scenario: Map Server MCP-App Configured
    GIVEN the agent deployment configuration
    WHEN MAP_SERVER_URL is set
    THEN the configuration includes the MCP server endpoint URL
    """
    with patch.dict(os.environ, {'MAP_SERVER_URL': 'http://localhost:3001/mcp'}):
        from agent.mcp_apps import get_mcp_apps_config
        config = get_mcp_apps_config()

        assert config.map_server_url == 'http://localhost:3001/mcp'
        assert config.map_server_enabled is True


def test_mcp_app_disabled_by_default():
    """
    Scenario: MCP-App Disabled by Default
    GIVEN no MCP-App configuration is provided
    WHEN the agent starts
    THEN no external MCP-Apps are connected
    AND the agent operates with internal MCP tools only
    """
    with patch.dict(os.environ, {}, clear=True):
        os.environ.pop('MAP_SERVER_URL', None)

        from agent.mcp_apps import get_mcp_apps_config
        config = get_mcp_apps_config()

        assert config.map_server_enabled is False
        assert not config.map_server_url


def test_config_empty_url():
    with patch.dict(os.environ, {'MAP_SERVER_URL': ''}, clear=True):
        from agent.mcp_apps import get_mcp_apps_config
        config = get_mcp_apps_config()
        assert config.map_server_enabled is False


def test_config_whitespace_url():
    with patch.dict(os.environ, {'MAP_SERVER_URL': '   '}, clear=True):
        from agent.mcp_apps import get_mcp_apps_config
        config = get_mcp_apps_config()
        assert config.map_server_enabled is False


# =============================================================================
# Requirement: Multi-MCP Server Orchestration (backend-agent spec)
# =============================================================================

def test_call_map_server_tool_success():
    """
    Scenario: Agent Connects to Map Server MCP
    GIVEN the agent is configured with the map server MCP endpoint
    WHEN the agent calls a tool on the map server
    THEN the MCP content items are returned from the SSE response
    AND the request uses MCP JSON-RPC tools/call method
    AND the Accept header includes both application/json and text/event-stream
    """
    with patch.dict(os.environ, {'MAP_SERVER_URL': 'http://localhost:3001/mcp'}):
        with patch('agent.mcp_apps.httpx') as mock_httpx:
            mock_httpx.post.return_value = _mock_http_response(
                _geocode_content()
            )

            from agent.mcp_apps import call_map_server_tool
            result = call_map_server_tool('geocode', query='London')

            assert result is not None
            assert isinstance(result, list)
            assert result[0]['type'] == 'text'

            call_args = mock_httpx.post.call_args
            payload = call_args[1]['json']
            assert payload['jsonrpc'] == '2.0'
            assert payload['method'] == 'tools/call'
            assert payload['params']['name'] == 'geocode'
            assert payload['params']['arguments']['query'] == 'London'

            headers = call_args[1]['headers']
            assert 'text/event-stream' in headers['Accept']
            assert 'application/json' in headers['Accept']


def test_call_map_server_tool_connection_error():
    """
    Scenario: Map Server MCP Unavailable
    GIVEN the agent is configured with map server endpoint
    WHEN the MCP server is unreachable
    THEN the function returns None (graceful failure)
    AND does not raise an exception
    """
    with patch.dict(os.environ, {'MAP_SERVER_URL': 'http://localhost:3001/mcp'}):
        with patch('agent.mcp_apps.httpx') as mock_httpx:
            mock_httpx.post.side_effect = Exception("Connection refused")

            from agent.mcp_apps import call_map_server_tool
            result = call_map_server_tool('geocode', query='London')

            assert result is None


def test_call_map_server_tool_not_configured():
    """
    Edge case: Map server not configured
    GIVEN no MAP_SERVER_URL is set
    WHEN call_map_server_tool is called
    THEN it returns None immediately without making any HTTP request
    """
    with patch.dict(os.environ, {}, clear=True):
        from agent.mcp_apps import call_map_server_tool
        result = call_map_server_tool('geocode', query='London')
        assert result is None


def test_call_map_server_tool_http_error():
    """Edge case: HTTP 500 error from MCP server"""
    with patch.dict(os.environ, {'MAP_SERVER_URL': 'http://localhost:3001/mcp'}):
        with patch('agent.mcp_apps.httpx') as mock_httpx:
            mock_response = MagicMock()
            mock_response.status_code = 500
            mock_httpx.post.return_value = mock_response

            from agent.mcp_apps import call_map_server_tool
            result = call_map_server_tool('geocode', query='London')

            assert result is None


def test_call_map_server_tool_invalid_sse():
    """Edge case: Response is not valid SSE / JSON"""
    with patch.dict(os.environ, {'MAP_SERVER_URL': 'http://localhost:3001/mcp'}):
        with patch('agent.mcp_apps.httpx') as mock_httpx:
            mock_response = MagicMock()
            mock_response.status_code = 200
            mock_response.text = "not sse format at all"
            mock_httpx.post.return_value = mock_response

            from agent.mcp_apps import call_map_server_tool
            result = call_map_server_tool('geocode', query='London')

            assert result is None


# =============================================================================
# Requirement: Geocode Merchant Name (googlemaps-catalog spec)
# =============================================================================

def test_geocode_merchant_success():
    """
    Scenario: Geocode Merchant Name
    GIVEN a transaction with description "Tesco Superstore"
    WHEN the agent calls the geocode tool on the map server
    THEN the tool returns latitude and longitude extracted from the text response
    AND the display_name from the first result is used as the label
    """
    with patch.dict(os.environ, {'MAP_SERVER_URL': 'http://localhost:3001/mcp'}):
        with patch('agent.mcp_apps.call_map_server_tool') as mock_call:
            mock_call.return_value = _geocode_content(
                lat="51.5074", lon="-0.1278", name="Tesco Extra, Isleworth, London"
            )

            from agent.mcp_apps import geocode_merchant
            result = geocode_merchant('Tesco Superstore')

            assert result is not None
            assert result['latitude'] == pytest.approx(51.5074)
            assert result['longitude'] == pytest.approx(-0.1278)
            assert result['label'] == 'Tesco Extra, Isleworth, London'


def test_geocode_merchant_multiple_results_uses_first():
    """
    Edge case: Geocode returns multiple results — first coordinates are used
    """
    with patch.dict(os.environ, {'MAP_SERVER_URL': 'http://localhost:3001/mcp'}):
        with patch('agent.mcp_apps.call_map_server_tool') as mock_call:
            text = (
                "1. Tesco Extra, Isleworth, TW7\n"
                "   Coordinates: 51.459007, -0.337418\n"
                "   Bounding box: W:-0.3384, S:51.4585, E:-0.3367, N:51.4597\n\n"
                "2. Tesco, Lewisham, SE13\n"
                "   Coordinates: 51.466403, -0.012478\n"
                "   Bounding box: W:-0.0135, S:51.4659, E:-0.0118, N:51.4669"
            )
            mock_call.return_value = [{"type": "text", "text": text}]

            from agent.mcp_apps import geocode_merchant
            result = geocode_merchant('Tesco Superstore')

            assert result is not None
            assert result['latitude'] == pytest.approx(51.459007)
            assert result['longitude'] == pytest.approx(-0.337418)


def test_geocode_merchant_fails_no_content():
    """
    Scenario: Geocode Fails — call_map_server_tool returns None
    """
    with patch.dict(os.environ, {'MAP_SERVER_URL': 'http://localhost:3001/mcp'}):
        with patch('agent.mcp_apps.call_map_server_tool') as mock_call:
            mock_call.return_value = None

            from agent.mcp_apps import geocode_merchant
            result = geocode_merchant('Online Purchase')

            assert result is None


def test_geocode_merchant_no_coordinates_in_text():
    """
    Edge case: Text content has no 'Coordinates:' line
    """
    with patch.dict(os.environ, {'MAP_SERVER_URL': 'http://localhost:3001/mcp'}):
        with patch('agent.mcp_apps.call_map_server_tool') as mock_call:
            mock_call.return_value = [{"type": "text", "text": "No results found."}]

            from agent.mcp_apps import geocode_merchant
            result = geocode_merchant('Nowhere')

            assert result is None


def test_geocode_merchant_invalid_latitude():
    """Edge case: Latitude out of valid range (-90 to 90)"""
    with patch.dict(os.environ, {'MAP_SERVER_URL': 'http://localhost:3001/mcp'}):
        with patch('agent.mcp_apps.call_map_server_tool') as mock_call:
            mock_call.return_value = _geocode_content(lat="200.0", lon="-0.1278")

            from agent.mcp_apps import geocode_merchant
            result = geocode_merchant('Invalid Place')

            assert result is None


def test_geocode_merchant_invalid_longitude():
    """Edge case: Longitude out of valid range (-180 to 180)"""
    with patch.dict(os.environ, {'MAP_SERVER_URL': 'http://localhost:3001/mcp'}):
        with patch('agent.mcp_apps.call_map_server_tool') as mock_call:
            mock_call.return_value = _geocode_content(lat="51.5074", lon="-300.0")

            from agent.mcp_apps import geocode_merchant
            result = geocode_merchant('Invalid Place')

            assert result is None


def test_geocode_merchant_non_text_content_ignored():
    """Edge case: Content item with type != 'text' is skipped"""
    with patch.dict(os.environ, {'MAP_SERVER_URL': 'http://localhost:3001/mcp'}):
        with patch('agent.mcp_apps.call_map_server_tool') as mock_call:
            mock_call.return_value = [{"type": "image", "data": "base64..."}]

            from agent.mcp_apps import geocode_merchant
            result = geocode_merchant('Somewhere')

            assert result is None


# =============================================================================
# Requirement: Geocode with Bounding Box
# =============================================================================

def test_geocode_with_bbox_success():
    """
    Scenario: Geocode with bbox returns coordinates and bounding box
    GIVEN a valid geocode response with bounding box
    WHEN geocode_with_bbox is called
    THEN the result includes latitude, longitude, label, west, south, east, north
    """
    with patch.dict(os.environ, {'MAP_SERVER_URL': 'http://localhost:3001/mcp'}):
        with patch('agent.mcp_apps.call_map_server_tool') as mock_call:
            mock_call.return_value = _geocode_content(
                lat="51.459007", lon="-0.337418", name="Tesco Extra, Isleworth, London"
            )

            from agent.mcp_apps import geocode_with_bbox
            result = geocode_with_bbox('Tesco Superstore')

            assert result is not None
            assert result['latitude'] == pytest.approx(51.459007)
            assert result['longitude'] == pytest.approx(-0.337418)
            assert result['label'] == 'Tesco Extra, Isleworth, London'
            # Bounding box from _geocode_text default: W:-0.5, S:51.0, E:0.5, N:52.0
            assert result['west'] == pytest.approx(-0.5)
            assert result['south'] == pytest.approx(51.0)
            assert result['east'] == pytest.approx(0.5)
            assert result['north'] == pytest.approx(52.0)


def test_geocode_with_bbox_fallback_when_no_bbox_line():
    """
    Edge case: Text has no Bounding box line — falls back to small bbox around point
    """
    with patch.dict(os.environ, {'MAP_SERVER_URL': 'http://localhost:3001/mcp'}):
        with patch('agent.mcp_apps.call_map_server_tool') as mock_call:
            mock_call.return_value = [{"type": "text", "text": (
                "1. Some Place\n"
                "   Coordinates: 51.5074, -0.1278\n"
                "   (no bounding box)"
            )}]

            from agent.mcp_apps import geocode_with_bbox
            result = geocode_with_bbox('Some Place')

            assert result is not None
            assert result['latitude'] == pytest.approx(51.5074)
            assert result['longitude'] == pytest.approx(-0.1278)
            # Fallback bbox: ±0.01 around the point
            assert result['west'] == pytest.approx(-0.1378)
            assert result['south'] == pytest.approx(51.4974)
            assert result['east'] == pytest.approx(-0.1178)
            assert result['north'] == pytest.approx(51.5174)


def test_geocode_with_bbox_fails_no_content():
    """
    Scenario: Geocode with bbox fails — call_map_server_tool returns None
    """
    with patch.dict(os.environ, {'MAP_SERVER_URL': 'http://localhost:3001/mcp'}):
        with patch('agent.mcp_apps.call_map_server_tool') as mock_call:
            mock_call.return_value = None

            from agent.mcp_apps import geocode_with_bbox
            result = geocode_with_bbox('Online Purchase')

            assert result is None


def test_geocode_with_bbox_invalid_coords():
    """
    Edge case: Invalid coordinates are rejected even with valid bbox
    """
    with patch.dict(os.environ, {'MAP_SERVER_URL': 'http://localhost:3001/mcp'}):
        with patch('agent.mcp_apps.call_map_server_tool') as mock_call:
            mock_call.return_value = _geocode_content(lat="200.0", lon="-0.1278")

            from agent.mcp_apps import geocode_with_bbox
            result = geocode_with_bbox('Invalid Place')

            assert result is None
