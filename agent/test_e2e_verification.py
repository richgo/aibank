"""
Scenario tests for Task 3.6: Verify agent end-to-end with A2A protocol
Tests the full A2A contract: /a2a/message/stream, /a2a/message, /a2a/agent-card

These tests verify the agent responds correctly via A2A endpoints
(which ADK web UI would use).
"""
import json

from fastapi.testclient import TestClient
import jsonschema

from agent.agent import app
from agent.a2ui_schema import A2UI_SCHEMA


def test_a2a_agent_card_endpoint():
    """
    Scenario: A2A Agent Card is Discoverable
    GIVEN the agent is running
    WHEN a client requests /a2a/agent-card
    THEN the agent returns its capabilities including A2UI extension
    """
    client = TestClient(app)
    
    # WHEN we request the agent card
    response = client.get("/a2a/agent-card")
    
    # THEN it returns successfully
    assert response.status_code == 200
    card = response.json()
    
    # AND it has required fields
    assert "name" in card
    assert "capabilities" in card
    
    # AND it declares A2UI support
    extensions = card["capabilities"]["extensions"]
    a2ui_ext = next((e for e in extensions if "a2ui" in e["uri"]), None)
    assert a2ui_ext is not None


def test_a2a_message_endpoint_account_overview():
    """
    Scenario: A2A Message Endpoint Returns Account Overview
    GIVEN the agent is running
    WHEN a client sends "show my accounts" via /a2a/message
    THEN the agent returns a complete A2A message with A2UI data parts
    """
    client = TestClient(app)
    
    # WHEN we send a message via A2A protocol
    payload = {
        "message": {
            "parts": [
                {"kind": "text", "text": "show my accounts"}
            ]
        }
    }
    response = client.post("/a2a/message", json=payload)
    
    # THEN it returns successfully
    assert response.status_code == 200
    result = response.json()
    
    # AND it has the message structure
    assert "kind" in result
    assert result["kind"] == "message"
    assert "parts" in result
    
    # AND it contains text and A2UI data parts
    parts = result["parts"]
    assert len(parts) > 1
    
    text_parts = [p for p in parts if p.get("kind") == "text"]
    assert len(text_parts) >= 1
    
    data_parts = [p for p in parts if p.get("kind") == "data"]
    assert len(data_parts) > 0
    
    # AND the data parts have A2UI mime type
    for part in data_parts:
        assert part.get("metadata", {}).get("mimeType") == "application/json+a2ui"
        
        # AND the A2UI data is valid
        a2ui_data = part.get("data")
        assert a2ui_data is not None
        jsonschema.validate(instance=[a2ui_data], schema=A2UI_SCHEMA)


def test_a2a_message_stream_endpoint():
    """
    Scenario: A2A Message Stream Endpoint Returns NDJSON
    GIVEN the agent is running
    WHEN a client sends a message via /a2a/message/stream
    THEN the agent returns NDJSON-formatted message parts
    """
    client = TestClient(app)
    
    # WHEN we send a streaming request
    payload = {
        "message": {
            "parts": [
                {"kind": "text", "text": "show transactions"}
            ]
        }
    }
    response = client.post("/a2a/message/stream", json=payload)
    
    # THEN it returns successfully with NDJSON
    assert response.status_code == 200
    assert "ndjson" in response.headers["content-type"]
    
    # AND we can parse the lines
    lines = response.text.strip().split("\n")
    assert len(lines) > 0
    
    # AND each line is valid JSON
    for line in lines:
        event = json.loads(line)
        assert "kind" in event
        assert event["kind"] == "message_part"
        assert "part" in event


def test_a2a_jsonrpc_message_send():
    """
    Scenario: A2A JSON-RPC message/send Method
    GIVEN the agent is running
    WHEN a client sends a message via JSON-RPC method "message/send"
    THEN the agent returns a task result with the message
    """
    client = TestClient(app)
    
    # WHEN we send a JSON-RPC request
    payload = {
        "jsonrpc": "2.0",
        "id": 123,
        "method": "message/send",
        "params": {
            "message": {
                "parts": [
                    {"kind": "text", "text": "what's my mortgage balance?"}
                ]
            }
        }
    }
    response = client.post("/", json=payload)
    
    # THEN it returns successfully
    assert response.status_code == 200
    result = response.json()
    
    # AND it has JSON-RPC structure
    assert result["jsonrpc"] == "2.0"
    assert result["id"] == 123
    assert "result" in result
    
    # AND the result is a task
    task = result["result"]
    assert task["kind"] == "task"
    assert "status" in task
    assert task["status"]["state"] == "completed"
    
    # AND the task contains the message
    message = task["status"]["message"]
    assert "parts" in message


def test_query_show_my_accounts():
    """
    Scenario: Query "show my accounts" Returns Account Data
    GIVEN the agent is running with MCP server
    WHEN the user queries "show my accounts"
    THEN the agent returns account overview with A2UI
    """
    client = TestClient(app)
    
    # WHEN we send the query
    response = client.post("/chat", json={"message": "show my accounts"})
    
    # THEN it returns successfully
    assert response.status_code == 200
    data = response.json()
    
    # AND contains account data
    assert "data" in data
    assert "accounts" in data["data"]
    assert len(data["data"]["accounts"]) > 0
    
    # AND contains valid A2UI
    assert "a2ui" in data
    jsonschema.validate(instance=data["a2ui"], schema=A2UI_SCHEMA)


def test_query_show_transactions():
    """
    Scenario: Query "show transactions" Returns Transaction Data
    GIVEN the agent is running with MCP server
    WHEN the user queries "show transactions"
    THEN the agent returns transaction list with A2UI
    """
    client = TestClient(app)
    
    # WHEN we send the query
    response = client.post("/chat", json={"message": "show transactions"})
    
    # THEN it returns successfully
    assert response.status_code == 200
    data = response.json()
    
    # AND contains transaction data
    assert "data" in data
    assert "transactions" in data["data"]
    
    # AND contains valid A2UI
    assert "a2ui" in data
    jsonschema.validate(instance=data["a2ui"], schema=A2UI_SCHEMA)


def test_query_mortgage_balance():
    """
    Scenario: Query "mortgage balance" Returns Mortgage Data
    GIVEN the agent is running with MCP server
    WHEN the user queries "mortgage balance"
    THEN the agent returns mortgage summary with A2UI
    """
    client = TestClient(app)
    
    # WHEN we send the query
    response = client.post("/chat", json={"message": "mortgage balance"})
    
    # THEN it returns successfully
    assert response.status_code == 200
    data = response.json()
    
    # AND contains mortgage data
    assert "data" in data
    assert "propertyAddress" in data["data"]
    
    # AND contains valid A2UI
    assert "a2ui" in data
    jsonschema.validate(instance=data["a2ui"], schema=A2UI_SCHEMA)


def test_query_credit_card_statement():
    """
    Scenario: Query "credit card statement" Returns Credit Card Data
    GIVEN the agent is running with MCP server
    WHEN the user queries "credit card statement"
    THEN the agent returns credit card statement with A2UI
    """
    client = TestClient(app)
    
    # WHEN we send the query
    response = client.post("/chat", json={"message": "credit card statement"})
    
    # THEN it returns successfully
    assert response.status_code == 200
    data = response.json()
    
    # AND contains credit card data
    assert "data" in data
    assert "cardNumber" in data["data"]
    
    # AND contains valid A2UI
    assert "a2ui" in data
    jsonschema.validate(instance=data["a2ui"], schema=A2UI_SCHEMA)
