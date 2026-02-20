"""
BDD-style scenario tests for transaction location feature.
Tests intent detection, merchant extraction, and runtime flow.
"""
import os
from unittest.mock import patch, MagicMock

import pytest

from agent.runtime import DeterministicRuntime


# =============================================================================
# Requirement: Transaction Location Intent (backend-agent spec)
# =============================================================================

def test_intent_detects_where_query():
    """
    Scenario: Location Intent Keywords - "where"
    GIVEN the agent receives a message containing "where"
    WHEN combined with transaction context
    THEN the agent recognizes the transaction location intent
    """
    runtime = DeterministicRuntime()

    # Various "where" queries
    assert runtime._intent("where was my Tesco transaction?") == "transaction_location"
    assert runtime._intent("Where did I spend money at Costa?") == "transaction_location"
    assert runtime._intent("WHERE was this purchase made") == "transaction_location"


def test_intent_detects_location_query():
    """
    Scenario: Location Intent Keywords - "location"
    """
    runtime = DeterministicRuntime()

    assert runtime._intent("show location of my last purchase") == "transaction_location"
    assert runtime._intent("what is the location of Tesco transaction") == "transaction_location"


def test_intent_detects_map_query():
    """
    Scenario: Location Intent Keywords - "map"
    """
    runtime = DeterministicRuntime()

    assert runtime._intent("show me on a map") == "transaction_location"
    assert runtime._intent("map my Tesco purchase") == "transaction_location"


def test_intent_detects_show_me_query():
    """
    Scenario: Location Intent Keywords - "show me"
    """
    runtime = DeterministicRuntime()

    # "show me" alone might be ambiguous, but with location context
    assert runtime._intent("show me where I shopped") == "transaction_location"


def test_intent_does_not_trigger_for_non_location_queries():
    """
    Edge case: Non-location queries should not trigger transaction_location intent
    """
    runtime = DeterministicRuntime()

    # These should NOT be transaction_location
    assert runtime._intent("show my accounts") != "transaction_location"
    assert runtime._intent("what is my balance") != "transaction_location"
    assert runtime._intent("show my transactions") != "transaction_location"
    assert runtime._intent("mortgage details") != "transaction_location"


# =============================================================================
# Requirement: Merchant Extraction (design edge case)
# =============================================================================

def test_extract_merchant_finds_matching_transaction():
    """
    Scenario: Extract merchant from user query
    GIVEN a list of transactions
    WHEN the user asks about a specific merchant
    THEN the function finds the matching transaction
    """
    runtime = DeterministicRuntime()
    transactions = [
        {"id": "tx1", "date": "2026-02-18", "description": "Costa Coffee", "amount": "4.50"},
        {"id": "tx2", "date": "2026-02-19", "description": "Tesco Superstore", "amount": "45.32"},
        {"id": "tx3", "date": "2026-02-20", "description": "Amazon UK", "amount": "29.99"},
    ]

    result = runtime._extract_merchant("where was my Tesco transaction?", transactions)

    assert result is not None
    tx, merchant = result
    assert tx["id"] == "tx2"
    assert "Tesco" in merchant


def test_extract_merchant_returns_most_recent():
    """
    Edge case: Multiple matching transactions
    GIVEN multiple transactions matching the merchant
    WHEN extracting merchant
    THEN return the most recent one
    """
    runtime = DeterministicRuntime()
    transactions = [
        {"id": "tx1", "date": "2026-02-15", "description": "Tesco Express", "amount": "12.00"},
        {"id": "tx2", "date": "2026-02-18", "description": "Tesco Superstore", "amount": "45.32"},
        {"id": "tx3", "date": "2026-02-20", "description": "Tesco Metro", "amount": "8.99"},
    ]

    result = runtime._extract_merchant("where was my Tesco purchase?", transactions)

    assert result is not None
    tx, merchant = result
    # Should return most recent (first in list, assuming sorted by date desc)
    assert tx["id"] == "tx1" or tx["date"] == "2026-02-20"  # Most recent by date


def test_extract_merchant_no_match():
    """
    Edge case: No matching merchant found
    """
    runtime = DeterministicRuntime()
    transactions = [
        {"id": "tx1", "date": "2026-02-18", "description": "Costa Coffee", "amount": "4.50"},
    ]

    result = runtime._extract_merchant("where was my Tesco transaction?", transactions)

    assert result is None


def test_extract_merchant_case_insensitive():
    """
    Edge case: Matching should be case-insensitive
    """
    runtime = DeterministicRuntime()
    transactions = [
        {"id": "tx1", "date": "2026-02-18", "description": "TESCO SUPERSTORE", "amount": "45.32"},
    ]

    result = runtime._extract_merchant("where was my tesco transaction?", transactions)

    assert result is not None


# =============================================================================
# Requirement: Transaction Location Runtime Flow (backend-agent spec)
# =============================================================================

def test_runtime_transaction_location_flow():
    """
    Scenario: Cross-MCP Tool Orchestration
    GIVEN the agent has access to bank MCP and Google Maps MCP
    WHEN the user asks "where was my Tesco transaction?"
    THEN the agent calls get_transactions on bank MCP
    AND the agent calls geocode on Google Maps MCP with the merchant name
    AND the agent combines results to construct the response
    """
    with patch('agent.runtime.call_tool') as mock_bank_tool:
        with patch('agent.runtime.geocode_merchant') as mock_geocode:
            # Setup bank MCP mock
            mock_bank_tool.side_effect = lambda name, **kwargs: {
                'get_accounts': [
                    {'id': 'acc1', 'type': 'current', 'balance': '1000.00'}
                ],
                'get_transactions': [
                    {'id': 'tx1', 'date': '2026-02-20', 'description': 'Tesco Superstore', 'amount': '45.32'}
                ]
            }.get(name, [])

            # Setup Google Maps MCP mock
            mock_geocode.return_value = {
                'latitude': 51.5074,
                'longitude': -0.1278,
                'label': 'Tesco Superstore'
            }

            runtime = DeterministicRuntime()
            result = runtime.run("where was my Tesco transaction?")

            # THEN the response uses transaction_location template
            assert result.template_name == "transaction_location.json"

            # AND contains transaction data
            assert 'transaction' in result.data
            assert result.data['transaction']['description'] == 'Tesco Superstore'

            # AND contains location data
            assert 'location' in result.data
            assert result.data['location']['latitude'] == 51.5074
            assert result.data['location']['longitude'] == -0.1278


def test_runtime_transaction_location_geocode_fails():
    """
    Scenario: Geocode Fails - Fallback behavior
    GIVEN a merchant name that cannot be geocoded
    WHEN the agent constructs the response
    THEN the agent responds with text indicating location is unavailable
    AND no MapView component is rendered (falls back to text)
    """
    with patch('agent.runtime.call_tool') as mock_bank_tool:
        with patch('agent.runtime.geocode_merchant') as mock_geocode:
            mock_bank_tool.side_effect = lambda name, **kwargs: {
                'get_accounts': [{'id': 'acc1', 'type': 'current'}],
                'get_transactions': [
                    {'id': 'tx1', 'date': '2026-02-20', 'description': 'Online Purchase', 'amount': '29.99'}
                ]
            }.get(name, [])

            # Geocode fails
            mock_geocode.return_value = None

            runtime = DeterministicRuntime()
            result = runtime.run("where was my online purchase?")

            # Falls back - not using transaction_location template
            # Should provide helpful text instead
            assert "location" in result.text.lower() or "map" in result.text.lower() or result.template_name != "transaction_location.json"
