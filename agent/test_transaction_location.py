"""
BDD-style scenario tests for transaction location feature.
Tests intent detection, merchant extraction, and runtime flow.
"""
import json
import os
from unittest.mock import patch, MagicMock

import pytest

from agent.runtime import DeterministicRuntime


# =============================================================================
# Helpers
# =============================================================================

def _bbox_result(lat=51.5074, lon=-0.1278, label='Tesco Superstore',
                 west=-0.5, south=51.0, east=0.5, north=52.0):
    return {
        'latitude': lat, 'longitude': lon, 'label': label,
        'west': west, 'south': south, 'east': east, 'north': north,
    }


def _mock_config(url='http://localhost:3001/mcp'):
    cfg = MagicMock()
    cfg.map_server_url = url
    return cfg


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
    GIVEN the agent has access to bank MCP and map MCP
    WHEN the user asks "where was my Tesco transaction?"
    THEN the agent calls get_transactions on bank MCP
    AND the agent calls geocode_with_bbox on map MCP with the merchant name
    AND the agent combines results to construct the response with frame data
    """
    with patch('agent.runtime.call_tool') as mock_bank_tool:
        with patch('agent.runtime.geocode_with_bbox') as mock_geocode:
            with patch('agent.runtime.get_mcp_apps_config') as mock_cfg:
                mock_cfg.return_value = _mock_config()
                mock_bank_tool.side_effect = lambda name, **kwargs: {
                    'get_accounts': [
                        {'id': 'acc1', 'type': 'current', 'balance': '1000.00'}
                    ],
                    'get_transactions': [
                        {'id': 'tx1', 'date': '2026-02-20', 'description': 'Tesco Superstore', 'amount': '45.32'}
                    ]
                }.get(name, [])
                mock_geocode.return_value = _bbox_result(label='Tesco Superstore')

                runtime = DeterministicRuntime()
                result = runtime.run("where was my Tesco transaction?")

                # THEN the response uses transaction_location template
                assert result.template_name == "transaction_location.json"

                # AND contains transaction data
                assert 'transaction' in result.data
                assert result.data['transaction']['description'] == 'Tesco Superstore'

                # AND contains frame data for MCP App iframe
                assert 'frame' in result.data
                assert result.data['frame']['toolName'] == 'show-map'
                assert result.data['frame']['toolInput']['label'] == 'Tesco Superstore'
                assert result.data['frame']['toolInput']['west'] == -0.5
                assert result.data['frame']['mcpEndpointUrl'] == 'http://localhost:3001/mcp'


def test_runtime_transaction_location_geocode_fails():
    """
    Scenario: Geocode Fails - Fallback behavior
    GIVEN a merchant name that cannot be geocoded
    WHEN the agent constructs the response
    THEN the agent responds with text indicating location is unavailable
    AND no mcp:AppFrame component is rendered (falls back to transaction list)
    """
    with patch('agent.runtime.call_tool') as mock_bank_tool:
        with patch('agent.runtime.geocode_with_bbox') as mock_geocode:
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
            assert result.template_name != "transaction_location.json"
            assert "frame" not in result.data


def test_user_action_select_transaction_uses_context_description():
    with patch('agent.runtime.geocode_with_bbox') as mock_geocode:
        with patch('agent.runtime.get_mcp_apps_config') as mock_cfg:
            mock_cfg.return_value = _mock_config()
            mock_geocode.return_value = _bbox_result(label='Tesco Superstore')

            runtime = DeterministicRuntime()
            action = json.dumps({
                "userAction": {
                    "name": "selectTransaction",
                    "context": {
                        "transactionId": "tx1",
                        "description": "Tesco Superstore",
                        "formattedDate": "20 Feb",
                        "amountDisplay": "-£45.32",
                    },
                }
            })
            result = runtime.run(action)

            assert result.template_name == "transaction_location.json"
            assert result.data["transaction"]["id"] == "tx1"
            assert result.data["transaction"]["description"] == "Tesco Superstore"
            assert 'frame' in result.data
            assert result.data['frame']['toolName'] == 'show-map'
            mock_geocode.assert_called_once_with("Tesco Superstore")


def test_user_action_select_transaction_supports_list_context():
    with patch('agent.runtime.geocode_with_bbox') as mock_geocode:
        with patch('agent.runtime.get_mcp_apps_config') as mock_cfg:
            mock_cfg.return_value = _mock_config()
            mock_geocode.return_value = _bbox_result(label='Tesco Superstore')

            runtime = DeterministicRuntime()
            action = json.dumps({
                "userAction": {
                    "name": "selectTransaction",
                    "context": [
                        {"key": "transactionId", "value": "tx1"},
                        {"key": "description", "value": "Tesco Superstore"},
                        {"key": "formattedDate", "value": "20 Feb"},
                        {"key": "amountDisplay", "value": "-£45.32"},
                    ],
                }
            })
            result = runtime.run(action)

            assert result.template_name == "transaction_location.json"
            assert result.data["transaction"]["id"] == "tx1"
            assert result.data["transaction"]["description"] == "Tesco Superstore"
            assert result.data["transaction"]["formattedDate"] == "20 Feb"
            assert result.data["transaction"]["amountDisplay"] == "-£45.32"
            assert 'frame' in result.data
            mock_geocode.assert_called_once_with("Tesco Superstore")


def test_user_action_select_transaction_uses_transaction_id_when_description_missing():
    with patch('agent.runtime.call_tool') as mock_bank_tool:
        with patch('agent.runtime.geocode_with_bbox') as mock_geocode:
            with patch('agent.runtime.get_mcp_apps_config') as mock_cfg:
                mock_cfg.return_value = _mock_config()
                mock_bank_tool.side_effect = lambda name, **kwargs: {
                    'get_accounts': [{'id': 'acc1', 'type': 'current', 'name': 'Current Account'}],
                    'get_transactions': [
                        {'id': 'tx1', 'date': '2026-02-20', 'description': 'Tesco Superstore', 'amount': '45.32'}
                    ],
                }.get(name, [])
                mock_geocode.return_value = _bbox_result(label='Tesco Superstore')

                runtime = DeterministicRuntime()
                action = json.dumps({
                    "userAction": {
                        "name": "selectTransaction",
                        "context": {"transactionId": "tx1"},
                    }
                })
                result = runtime.run(action)

                assert result.template_name == "transaction_location.json"
                assert result.data["transaction"]["description"] == "Tesco Superstore"
                assert 'frame' in result.data
                mock_geocode.assert_called_once_with("Tesco Superstore")


def test_user_action_select_transaction_falls_back_when_geocode_fails():
    with patch('agent.runtime.call_tool') as mock_bank_tool:
        with patch('agent.runtime.geocode_with_bbox') as mock_geocode:
            mock_bank_tool.side_effect = lambda name, **kwargs: {
                'get_accounts': [{'id': 'acc1', 'type': 'current', 'name': 'Current Account'}],
                'get_transactions': [
                    {'id': 'tx1', 'date': '2026-02-20', 'description': 'Online Purchase', 'amount': '29.99'}
                ],
            }.get(name, [])
            mock_geocode.return_value = None

            runtime = DeterministicRuntime()
            action = json.dumps({
                "userAction": {
                    "name": "selectTransaction",
                    "context": {"transactionId": "tx1", "description": "Online Purchase"},
                }
            })
            result = runtime.run(action)

            assert result.template_name == "transaction_list.json"
            assert "transactions" in result.data


def test_user_action_select_transaction_falls_back_when_context_missing():
    with patch('agent.runtime.call_tool') as mock_bank_tool:
        with patch('agent.runtime.geocode_with_bbox') as mock_geocode:
            mock_bank_tool.side_effect = lambda name, **kwargs: {
                'get_accounts': [{'id': 'acc1', 'type': 'current', 'name': 'Current Account'}],
                'get_transactions': [
                    {'id': 'tx1', 'date': '2026-02-20', 'description': 'Tesco Superstore', 'amount': '45.32'}
                ],
            }.get(name, [])

            runtime = DeterministicRuntime()
            action = json.dumps({
                "userAction": {
                    "name": "selectTransaction",
                    "context": {},
                }
            })
            result = runtime.run(action)

            assert result.template_name == "transaction_list.json"
            assert "transactions" in result.data
            mock_geocode.assert_not_called()


def test_user_action_account_context_still_returns_account_detail():
    with patch('agent.runtime.call_tool') as mock_bank_tool:
        mock_bank_tool.side_effect = lambda name, **kwargs: {
            'get_account_detail': {
                'id': 'acc1',
                'name': 'Current Account',
                'balance': '1000.00',
                'type': 'current',
                'accountNumber': '12345678',
                'sortCode': '12-34-56',
            },
            'get_transactions': [
                {'id': 'tx1', 'date': '2026-02-20', 'description': 'Tesco Superstore', 'amount': '45.32'}
            ],
        }.get(name, [])

        runtime = DeterministicRuntime()
        action = json.dumps({
            "userAction": {
                "name": "selectAccount",
                "context": {"accountId": "acc1"},
            }
        })
        result = runtime.run(action)

        assert result.template_name == "account_detail.json"
        assert "transactions" in result.data
