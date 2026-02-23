"""
MCP-Apps configuration and client functions.

This module provides:
- Configuration loading for external MCP-App connections
- Client functions for calling the map-server MCP tools

The map server is @modelcontextprotocol/server-map — an open-source CesiumJS +
OpenStreetMap/Nominatim server that requires no API keys. It runs on port 3001
and exposes two tools via MCP JSON-RPC:
  - geocode: searches for places by name, returns formatted text with coordinates
  - show-map: displays a 3D CesiumJS globe (not used; we render in Flutter)

Wire protocol notes:
  - The server uses StreamableHTTP transport; the Accept header MUST include
    both "application/json" and "text/event-stream" or the server returns 406.
  - Responses are SSE-formatted: lines of "event: ...\ndata: <json>\n\n".
  - The geocode tool returns human-readable text content, not JSON:
      "1. Place Name, Address\n   Coordinates: lat, lon\n   Bounding box: ..."
"""
from __future__ import annotations

import os
import re
from dataclasses import dataclass
from typing import Any

import httpx

_COORDS_RE = re.compile(r"Coordinates:\s*([-\d.]+),\s*([-\d.]+)")
_FIRST_NAME_RE = re.compile(r"^\d+\.\s+(.+?)(?:\s{2,}|\n|$)", re.MULTILINE)
_BBOX_RE = re.compile(r"Bounding box: W:([-\d.]+), S:([-\d.]+), E:([-\d.]+), N:([-\d.]+)")


@dataclass(frozen=True)
class McpAppsConfig:
    """Configuration for MCP-App connections."""

    map_server_url: str | None

    @property
    def map_server_enabled(self) -> bool:
        """Map server MCP-App is enabled if URL is set and non-empty."""
        return bool(self.map_server_url and self.map_server_url.strip())


def get_mcp_apps_config() -> McpAppsConfig:
    """
    Load MCP-Apps configuration from environment variables.

    Environment variables:
    - MAP_SERVER_URL: Full MCP endpoint URL for the map server
                      (e.g., http://localhost:3001/mcp)
                      Leave unset to disable the map server integration.

    Returns:
        McpAppsConfig with loaded settings
    """
    url = os.environ.get("MAP_SERVER_URL", "")

    if not url or not url.strip():
        url = None
    else:
        url = url.strip()

    return McpAppsConfig(map_server_url=url)


def call_map_server_tool(tool_name: str, **kwargs: Any) -> list[dict] | None:
    """
    Call a tool on the map-server via MCP JSON-RPC over HTTP.

    The map-server uses StreamableHTTPServerTransport at /mcp. The Accept header
    must include both application/json and text/event-stream; the server always
    responds in SSE format. We parse the first "data:" line as the JSON-RPC
    response and return the result.content list.

    Args:
        tool_name: MCP tool name ('geocode' or 'show-map')
        **kwargs: Arguments to pass to the tool

    Returns:
        List of MCP content items from the tool result, or None on failure.
        Each item is a dict with at least a 'type' key ('text', 'image', etc.).
    """
    config = get_mcp_apps_config()

    if not config.map_server_enabled:
        return None

    try:
        import json as _json

        payload = {
            "jsonrpc": "2.0",
            "id": 1,
            "method": "tools/call",
            "params": {
                "name": tool_name,
                "arguments": kwargs,
            },
        }

        response = httpx.post(
            config.map_server_url,
            json=payload,
            headers={
                "Content-Type": "application/json",
                # Both required — server returns 406 without text/event-stream
                "Accept": "application/json, text/event-stream",
            },
            timeout=30.0,
        )

        if response.status_code != 200:
            return None

        # Response is SSE: parse "data: <json>" lines
        for line in response.text.splitlines():
            line = line.strip()
            if not line.startswith("data:"):
                continue
            try:
                data = _json.loads(line[len("data:"):].strip())
            except ValueError:
                continue
            result = data.get("result", {})
            content = result.get("content")
            if isinstance(content, list):
                return content

        return None

    except Exception:
        return None


def geocode_merchant(query: str) -> dict[str, Any] | None:
    """
    Geocode a merchant name to get location coordinates.

    Calls the map-server's 'geocode' tool, which uses OpenStreetMap Nominatim.
    Results are returned as formatted human-readable text:
        "1. Place Name, Address
           Coordinates: lat, lon
           Bounding box: W:x, S:y, E:z, N:w"

    We extract the first result's coordinates using a regex on the text.

    Args:
        query: Merchant name or address to geocode

    Returns:
        Dict with 'latitude', 'longitude', 'label' if successful, else None.
        Returns None if:
        - Map server is not configured
        - Geocode call fails or times out
        - Response contains no coordinate data
        - Coordinates are out of valid range
    """
    content = call_map_server_tool("geocode", query=query)

    if not content:
        return None

    for item in content:
        if not isinstance(item, dict) or item.get("type") != "text":
            continue

        text = item.get("text", "")

        m = _COORDS_RE.search(text)
        if not m:
            continue

        try:
            lat = float(m.group(1))
            lon = float(m.group(2))
        except ValueError:
            continue

        if not (-90 <= lat <= 90) or not (-180 <= lon <= 180):
            continue

        name_m = _FIRST_NAME_RE.search(text)
        label = name_m.group(1).strip() if name_m else query

        return {"latitude": lat, "longitude": lon, "label": label}

    return None


def geocode_with_bbox(query: str) -> dict[str, Any] | None:
    """
    Geocode a merchant name to get location coordinates and bounding box.

    Like geocode_merchant but also returns the bounding box for use with the
    map server's show-map tool (west/south/east/north in decimal degrees).

    Args:
        query: Merchant name or address to geocode

    Returns:
        Dict with 'latitude', 'longitude', 'label', 'west', 'south', 'east',
        'north' if successful, else None.
    """
    content = call_map_server_tool("geocode", query=query)

    if not content:
        return None

    for item in content:
        if not isinstance(item, dict) or item.get("type") != "text":
            continue

        text = item.get("text", "")

        coords_m = _COORDS_RE.search(text)
        if not coords_m:
            continue

        try:
            lat = float(coords_m.group(1))
            lon = float(coords_m.group(2))
        except ValueError:
            continue

        if not (-90 <= lat <= 90) or not (-180 <= lon <= 180):
            continue

        name_m = _FIRST_NAME_RE.search(text)
        label = name_m.group(1).strip() if name_m else query

        bbox_m = _BBOX_RE.search(text)
        if bbox_m:
            try:
                west = float(bbox_m.group(1))
                south = float(bbox_m.group(2))
                east = float(bbox_m.group(3))
                north = float(bbox_m.group(4))
            except ValueError:
                west, south, east, north = lon - 0.01, lat - 0.01, lon + 0.01, lat + 0.01
        else:
            west, south, east, north = lon - 0.01, lat - 0.01, lon + 0.01, lat + 0.01

        return {
            "latitude": lat,
            "longitude": lon,
            "label": label,
            "west": west,
            "south": south,
            "east": east,
            "north": north,
        }

    return None
