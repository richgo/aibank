"""
BDD-style scenario tests for MCP-Apps Protocol spec.
Each test corresponds to a Given/When/Then scenario from specs/mcp-apps-protocol/spec.md
"""
import os
from unittest.mock import patch, MagicMock, AsyncMock
import pytest


# =============================================================================
# Requirement: MCP-App Configuration
# =============================================================================

def test_google_maps_mcp_app_configured():
    """
    Scenario: Google Maps MCP-App Configured
    GIVEN the agent deployment configuration
    WHEN the Google Maps MCP-App is enabled
    THEN the configuration includes the MCP server endpoint URL
    AND the configuration includes any required API keys
    """
    # GIVEN environment variables are set
    with patch.dict(os.environ, {
        'GOOGLE_MAPS_MCP_URL': 'https://maps.example.com/mcp',
        'GOOGLE_MAPS_API_KEY': 'test-api-key-123'
    }):
        # WHEN we load the MCP-Apps configuration
        from agent.mcp_apps import get_mcp_apps_config
        config = get_mcp_apps_config()

        # THEN the configuration includes the endpoint URL
        assert config.google_maps_url == 'https://maps.example.com/mcp'

        # AND the configuration includes the API key
        assert config.google_maps_api_key == 'test-api-key-123'

        # AND the Google Maps MCP-App is marked as enabled
        assert config.google_maps_enabled is True


def test_mcp_app_disabled_by_default():
    """
    Scenario: MCP-App Disabled by Default
    GIVEN no MCP-App configuration is provided
    WHEN the agent starts
    THEN no external MCP-Apps are connected
    AND the agent operates with internal MCP tools only
    """
    # GIVEN no environment variables are set
    with patch.dict(os.environ, {}, clear=True):
        # Remove any existing config env vars
        for key in ['GOOGLE_MAPS_MCP_URL', 'GOOGLE_MAPS_API_KEY']:
            os.environ.pop(key, None)

        # WHEN we load the MCP-Apps configuration
        from agent.mcp_apps import get_mcp_apps_config
        config = get_mcp_apps_config()

        # THEN Google Maps MCP-App is disabled
        assert config.google_maps_enabled is False

        # AND the URL and key are None or empty
        assert not config.google_maps_url
        assert not config.google_maps_api_key


# =============================================================================
# Edge Cases for MCP-Apps Configuration
# =============================================================================

# Edge cases for get_mcp_apps_config:
# - [ ] URL set but no API key → enabled (key optional for some endpoints)
# - [ ] API key set but no URL → disabled (URL is required)
# - [ ] Empty string URL → disabled
# - [ ] Whitespace-only URL → disabled
# - [ ] URL with trailing slash → normalized


def test_config_url_set_without_api_key():
    """
    Edge case: URL set but no API key
    Some MCP endpoints may not require API key authentication
    """
    with patch.dict(os.environ, {'GOOGLE_MAPS_MCP_URL': 'https://maps.example.com/mcp'}, clear=True):
        from agent.mcp_apps import get_mcp_apps_config
        config = get_mcp_apps_config()

        # Should still be enabled - key is optional
        assert config.google_maps_enabled is True
        assert config.google_maps_url == 'https://maps.example.com/mcp'
        assert config.google_maps_api_key is None


def test_config_api_key_without_url():
    """
    Edge case: API key set but no URL
    Cannot call MCP without knowing the endpoint
    """
    with patch.dict(os.environ, {'GOOGLE_MAPS_API_KEY': 'test-key'}, clear=True):
        from agent.mcp_apps import get_mcp_apps_config
        config = get_mcp_apps_config()

        # Should be disabled - URL is required
        assert config.google_maps_enabled is False


def test_config_empty_url():
    """
    Edge case: Empty string URL
    """
    with patch.dict(os.environ, {'GOOGLE_MAPS_MCP_URL': ''}, clear=True):
        from agent.mcp_apps import get_mcp_apps_config
        config = get_mcp_apps_config()

        assert config.google_maps_enabled is False


def test_config_whitespace_url():
    """
    Edge case: Whitespace-only URL
    """
    with patch.dict(os.environ, {'GOOGLE_MAPS_MCP_URL': '   '}, clear=True):
        from agent.mcp_apps import get_mcp_apps_config
        config = get_mcp_apps_config()

        assert config.google_maps_enabled is False


# =============================================================================
# Requirement: Multi-MCP Server Orchestration (backend-agent spec)
# =============================================================================

def test_call_googlemaps_tool_success():
    """
    Scenario: Agent Connects to Google Maps MCP
    GIVEN the agent is configured with Google Maps MCP endpoint
    WHEN the agent calls a tool on Google Maps MCP
    THEN the tool response is returned successfully
    """
    with patch.dict(os.environ, {
        'GOOGLE_MAPS_MCP_URL': 'https://maps.example.com/mcp',
        'GOOGLE_MAPS_API_KEY': 'test-key'
    }):
        # Mock httpx response
        with patch('agent.mcp_apps.httpx') as mock_httpx:
            mock_response = MagicMock()
            mock_response.status_code = 200
            mock_response.json.return_value = {
                'result': {
                    'latitude': 51.5074,
                    'longitude': -0.1278,
                    'formatted_address': 'London, UK'
                }
            }
            mock_httpx.post.return_value = mock_response

            from agent.mcp_apps import call_googlemaps_tool
            result = call_googlemaps_tool('geocode', query='London')

            # THEN the result contains the geocode response
            assert result is not None
            assert result['latitude'] == 51.5074
            assert result['longitude'] == -0.1278


def test_call_googlemaps_tool_connection_error():
    """
    Scenario: Google Maps MCP Unavailable
    GIVEN the agent is configured with Google Maps MCP endpoint
    WHEN the MCP server is unreachable
    THEN the function returns None (graceful failure)
    AND does not raise an exception
    """
    with patch.dict(os.environ, {
        'GOOGLE_MAPS_MCP_URL': 'https://maps.example.com/mcp',
    }):
        with patch('agent.mcp_apps.httpx') as mock_httpx:
            import httpx
            mock_httpx.post.side_effect = Exception("Connection refused")

            from agent.mcp_apps import call_googlemaps_tool
            result = call_googlemaps_tool('geocode', query='London')

            # THEN graceful failure - returns None
            assert result is None


def test_call_googlemaps_tool_not_configured():
    """
    Edge case: Google Maps MCP not configured
    GIVEN no GOOGLE_MAPS_MCP_URL is set
    WHEN call_googlemaps_tool is called
    THEN it returns None immediately
    """
    with patch.dict(os.environ, {}, clear=True):
        from agent.mcp_apps import call_googlemaps_tool
        result = call_googlemaps_tool('geocode', query='London')

        assert result is None


# Edge cases for call_googlemaps_tool:
# - [x] MCP not configured → returns None
# - [x] Connection error → returns None
# - [ ] HTTP 500 error → returns None
# - [ ] Invalid JSON response → returns None
# - [ ] Timeout → returns None


def test_call_googlemaps_tool_http_error():
    """
    Edge case: HTTP 500 error from MCP server
    """
    with patch.dict(os.environ, {'GOOGLE_MAPS_MCP_URL': 'https://maps.example.com/mcp'}):
        with patch('agent.mcp_apps.httpx') as mock_httpx:
            mock_response = MagicMock()
            mock_response.status_code = 500
            mock_response.json.return_value = {'error': 'Internal server error'}
            mock_httpx.post.return_value = mock_response

            from agent.mcp_apps import call_googlemaps_tool
            result = call_googlemaps_tool('geocode', query='London')

            assert result is None


def test_call_googlemaps_tool_invalid_json():
    """
    Edge case: Invalid JSON response from MCP server
    """
    with patch.dict(os.environ, {'GOOGLE_MAPS_MCP_URL': 'https://maps.example.com/mcp'}):
        with patch('agent.mcp_apps.httpx') as mock_httpx:
            mock_response = MagicMock()
            mock_response.status_code = 200
            mock_response.json.side_effect = ValueError("Invalid JSON")
            mock_httpx.post.return_value = mock_response

            from agent.mcp_apps import call_googlemaps_tool
            result = call_googlemaps_tool('geocode', query='London')

            assert result is None


# =============================================================================
# Requirement: Geocode Merchant Name (googlemaps-catalog spec)
# =============================================================================

def test_geocode_merchant_success():
    """
    Scenario: Geocode Merchant Name
    GIVEN a transaction with description "Tesco Superstore"
    WHEN the agent calls the geocode tool on Google Maps MCP
    THEN the tool returns latitude and longitude for a Tesco location
    AND the coordinates are suitable for display in MapView
    """
    with patch.dict(os.environ, {'GOOGLE_MAPS_MCP_URL': 'https://maps.example.com/mcp'}):
        with patch('agent.mcp_apps.call_googlemaps_tool') as mock_call:
            mock_call.return_value = {
                'latitude': 51.5074,
                'longitude': -0.1278,
                'formatted_address': 'Tesco Superstore, London'
            }

            from agent.mcp_apps import geocode_merchant
            result = geocode_merchant('Tesco Superstore')

            # THEN coordinates are returned
            assert result is not None
            assert result['latitude'] == 51.5074
            assert result['longitude'] == -0.1278
            assert result['label'] == 'Tesco Superstore'


def test_geocode_merchant_fails():
    """
    Scenario: Geocode Fails
    GIVEN a merchant name that cannot be geocoded (e.g., "Online Purchase")
    WHEN the agent calls the geocode tool
    THEN the tool returns an error or empty result
    AND the function returns None
    """
    with patch.dict(os.environ, {'GOOGLE_MAPS_MCP_URL': 'https://maps.example.com/mcp'}):
        with patch('agent.mcp_apps.call_googlemaps_tool') as mock_call:
            mock_call.return_value = None

            from agent.mcp_apps import geocode_merchant
            result = geocode_merchant('Online Purchase')

            assert result is None


# Edge cases for geocode_merchant:
# - [x] Successful geocode → returns {latitude, longitude, label}
# - [x] Geocode fails → returns None
# - [ ] Invalid coordinates (out of range) → returns None
# - [ ] Missing latitude in response → returns None
# - [ ] Missing longitude in response → returns None


def test_geocode_merchant_invalid_latitude():
    """
    Edge case: Latitude out of valid range (-90 to 90)
    """
    with patch.dict(os.environ, {'GOOGLE_MAPS_MCP_URL': 'https://maps.example.com/mcp'}):
        with patch('agent.mcp_apps.call_googlemaps_tool') as mock_call:
            mock_call.return_value = {
                'latitude': 200.0,  # Invalid
                'longitude': -0.1278,
            }

            from agent.mcp_apps import geocode_merchant
            result = geocode_merchant('Invalid Place')

            assert result is None


def test_geocode_merchant_invalid_longitude():
    """
    Edge case: Longitude out of valid range (-180 to 180)
    """
    with patch.dict(os.environ, {'GOOGLE_MAPS_MCP_URL': 'https://maps.example.com/mcp'}):
        with patch('agent.mcp_apps.call_googlemaps_tool') as mock_call:
            mock_call.return_value = {
                'latitude': 51.5074,
                'longitude': -300.0,  # Invalid
            }

            from agent.mcp_apps import geocode_merchant
            result = geocode_merchant('Invalid Place')

            assert result is None


def test_geocode_merchant_missing_latitude():
    """
    Edge case: Response missing latitude field
    """
    with patch.dict(os.environ, {'GOOGLE_MAPS_MCP_URL': 'https://maps.example.com/mcp'}):
        with patch('agent.mcp_apps.call_googlemaps_tool') as mock_call:
            mock_call.return_value = {
                'longitude': -0.1278,
            }

            from agent.mcp_apps import geocode_merchant
            result = geocode_merchant('Incomplete')

            assert result is None


def test_geocode_merchant_missing_longitude():
    """
    Edge case: Response missing longitude field
    """
    with patch.dict(os.environ, {'GOOGLE_MAPS_MCP_URL': 'https://maps.example.com/mcp'}):
        with patch('agent.mcp_apps.call_googlemaps_tool') as mock_call:
            mock_call.return_value = {
                'latitude': 51.5074,
            }

            from agent.mcp_apps import geocode_merchant
            result = geocode_merchant('Incomplete')

            assert result is None
