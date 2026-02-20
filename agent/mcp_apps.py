"""
MCP-Apps configuration and client functions.

This module provides:
- Configuration loading for external MCP-App connections
- Client functions for calling Google Maps MCP tools
"""
from __future__ import annotations

import os
from dataclasses import dataclass
from typing import Any

import httpx


@dataclass(frozen=True)
class McpAppsConfig:
    """Configuration for MCP-App connections."""

    google_maps_url: str | None
    google_maps_api_key: str | None

    @property
    def google_maps_enabled(self) -> bool:
        """Google Maps MCP-App is enabled if URL is set and non-empty."""
        return bool(self.google_maps_url and self.google_maps_url.strip())


def get_mcp_apps_config() -> McpAppsConfig:
    """
    Load MCP-Apps configuration from environment variables.

    Environment variables:
    - GOOGLE_MAPS_MCP_URL: Endpoint URL for Google Maps MCP server
    - GOOGLE_MAPS_API_KEY: API key for Google Maps (optional)

    Returns:
        McpAppsConfig with loaded settings
    """
    url = os.environ.get("GOOGLE_MAPS_MCP_URL", "")
    api_key = os.environ.get("GOOGLE_MAPS_API_KEY")

    # Normalize empty/whitespace URL to None
    if not url or not url.strip():
        url = None
    else:
        url = url.strip()

    return McpAppsConfig(
        google_maps_url=url,
        google_maps_api_key=api_key,
    )


def call_googlemaps_tool(tool_name: str, **kwargs: Any) -> dict[str, Any] | None:
    """
    Call a tool on the Google Maps MCP server.

    Args:
        tool_name: Name of the MCP tool to call (e.g., 'geocode')
        **kwargs: Arguments to pass to the tool

    Returns:
        Tool result as a dict, or None if the call failed or MCP is not configured
    """
    config = get_mcp_apps_config()

    if not config.google_maps_enabled:
        return None

    try:
        # Build request payload (MCP tool call format)
        payload = {
            "tool": tool_name,
            "arguments": kwargs,
        }

        # Add API key header if configured
        headers = {"Content-Type": "application/json"}
        if config.google_maps_api_key:
            headers["Authorization"] = f"Bearer {config.google_maps_api_key}"

        response = httpx.post(
            f"{config.google_maps_url}/tools/{tool_name}",
            json=payload,
            headers=headers,
            timeout=30.0,
        )

        if response.status_code != 200:
            return None

        data = response.json()
        return data.get("result")

    except Exception:
        # Connection error, timeout, invalid JSON, etc.
        return None
