"""
MCP-Apps configuration and client functions.

This module provides:
- Configuration loading for external MCP-App connections
- Client functions for calling Google Maps MCP tools
"""
from __future__ import annotations

import os
from dataclasses import dataclass


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
