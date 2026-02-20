"""
Task 8.3: A2A Contract Field Validation Tests

BDD scenarios ensuring A2A protocol compliance:
- POST /a2a/message/stream response schema
- POST /a2a/message response schema
- GET /a2a/agent-card response schema
- JSON-RPC envelope structure
"""
import json

from fastapi.testclient import TestClient
import jsonschema

from agent.agent import app


# Edge cases for A2A contract:
# - [ ] agent-card has all required fields
# - [ ] agent-card extensions array is valid
# - [ ] agent-card capabilities match spec
# - [ ] message response has correct envelope structure
# - [ ] message parts have correct kind values
# - [ ] data parts have mimeType metadata
# - [ ] stream response is valid NDJSON
# - [ ] JSON-RPC responses have correct id passthrough
# - [ ] task responses have all required fields


def test_agent_card_has_required_fields():
    """
    Scenario: Agent Card Contains Required Fields
    GIVEN the agent is running
    WHEN /a2a/agent-card is requested
    THEN the response contains name, description, and capabilities
    """
    client = TestClient(app)
    response = client.get("/a2a/agent-card")
    
    assert response.status_code == 200
    card = response.json()
    
    # Required top-level fields
    assert "name" in card, "agent-card must have 'name'"
    assert "description" in card, "agent-card must have 'description'"
    assert "capabilities" in card, "agent-card must have 'capabilities'"
    
    # Name must be non-empty string
    assert isinstance(card["name"], str)
    assert len(card["name"]) > 0
    
    # Description must be non-empty string
    assert isinstance(card["description"], str)
    assert len(card["description"]) > 0


def test_agent_card_capabilities_structure():
    """
    Scenario: Agent Card Capabilities Are Well-Formed
    GIVEN the agent card is retrieved
    WHEN examining the capabilities object
    THEN it contains a valid extensions array
    """
    client = TestClient(app)
    response = client.get("/a2a/agent-card")
    card = response.json()
    
    capabilities = card["capabilities"]
    assert "extensions" in capabilities
    assert isinstance(capabilities["extensions"], list)
    assert len(capabilities["extensions"]) > 0


def test_agent_card_a2ui_extension():
    """
    Scenario: Agent Card Declares A2UI Extension
    GIVEN the agent card capabilities
    WHEN examining the extensions
    THEN at least one extension has A2UI URI
    AND it declares supportedCatalogIds
    """
    client = TestClient(app)
    response = client.get("/a2a/agent-card")
    card = response.json()
    
    extensions = card["capabilities"]["extensions"]
    a2ui_ext = [e for e in extensions if "a2ui" in e.get("uri", "")]
    
    assert len(a2ui_ext) > 0, "agent-card must declare A2UI extension"
    
    ext = a2ui_ext[0]
    assert "uri" in ext
    assert "required" in ext
    assert "params" in ext
    
    params = ext["params"]
    assert "supportedCatalogIds" in params
    assert isinstance(params["supportedCatalogIds"], list)
    assert len(params["supportedCatalogIds"]) > 0


def test_agent_card_well_known_adds_url():
    """
    Scenario: Well-Known Agent Card Includes URL
    GIVEN the agent is running
    WHEN /.well-known/agent-card.json is requested
    THEN the response includes the agent's URL
    AND declares streaming capability
    """
    client = TestClient(app)
    response = client.get("/.well-known/agent-card.json")
    
    assert response.status_code == 200
    card = response.json()
    
    assert "url" in card, "well-known agent-card must include 'url'"
    assert "capabilities" in card
    assert "streaming" in card["capabilities"]
    assert card["capabilities"]["streaming"] is True


def test_message_response_envelope_structure():
    """
    Scenario: /a2a/message Response Has Correct Envelope
    GIVEN a message is sent via /a2a/message
    WHEN the response is received
    THEN it has 'kind' and 'parts' fields
    """
    client = TestClient(app)
    payload = {
        "message": {
            "parts": [{"kind": "text", "text": "test"}]
        }
    }
    
    response = client.post("/a2a/message", json=payload)
    assert response.status_code == 200
    
    result = response.json()
    assert "kind" in result
    assert result["kind"] == "message"
    assert "parts" in result
    assert isinstance(result["parts"], list)


def test_message_response_with_jsonrpc_id():
    """
    Scenario: /a2a/message Preserves JSON-RPC ID
    GIVEN a message with JSON-RPC id
    WHEN sent via /a2a/message
    THEN the response wraps the result with the same id
    """
    client = TestClient(app)
    payload = {
        "id": 42,
        "message": {
            "parts": [{"kind": "text", "text": "test"}]
        }
    }
    
    response = client.post("/a2a/message", json=payload)
    assert response.status_code == 200
    
    result = response.json()
    assert "jsonrpc" in result
    assert result["jsonrpc"] == "2.0"
    assert "id" in result
    assert result["id"] == 42
    assert "result" in result
    assert result["result"]["kind"] == "message"


def test_message_parts_have_valid_kinds():
    """
    Scenario: Message Parts Have Valid 'kind' Values
    GIVEN a message response
    WHEN examining the parts
    THEN each part has 'kind' as 'text' or 'data'
    """
    client = TestClient(app)
    payload = {
        "message": {
            "parts": [{"kind": "text", "text": "show accounts"}]
        }
    }
    
    response = client.post("/a2a/message", json=payload)
    result = response.json()
    
    parts = result["parts"]
    assert len(parts) > 0
    
    valid_kinds = {"text", "data"}
    for part in parts:
        assert "kind" in part, f"Part missing 'kind': {part}"
        assert part["kind"] in valid_kinds, f"Invalid kind: {part['kind']}"


def test_data_parts_have_mimetype():
    """
    Scenario: Data Parts Include MIME Type Metadata
    GIVEN a message response with A2UI data
    WHEN examining data parts
    THEN each has metadata.mimeType = 'application/json+a2ui'
    """
    client = TestClient(app)
    payload = {
        "message": {
            "parts": [{"kind": "text", "text": "show accounts"}]
        }
    }
    
    response = client.post("/a2a/message", json=payload)
    result = response.json()
    
    data_parts = [p for p in result["parts"] if p.get("kind") == "data"]
    assert len(data_parts) > 0, "Response should contain A2UI data parts"
    
    for part in data_parts:
        assert "metadata" in part, f"Data part missing 'metadata': {part}"
        assert "mimeType" in part["metadata"]
        assert part["metadata"]["mimeType"] == "application/json+a2ui"
        assert "data" in part


def test_stream_response_is_valid_ndjson():
    """
    Scenario: /a2a/message/stream Returns Valid NDJSON
    GIVEN a streaming message request
    WHEN the response is received
    THEN it is NDJSON (newline-delimited JSON)
    AND each line is a valid JSON object
    """
    client = TestClient(app)
    payload = {
        "message": {
            "parts": [{"kind": "text", "text": "test"}]
        }
    }
    
    response = client.post("/a2a/message/stream", json=payload)
    assert response.status_code == 200
    assert "ndjson" in response.headers["content-type"]
    
    lines = response.text.strip().split("\n")
    assert len(lines) > 0
    
    for line in lines:
        # Each line must be valid JSON
        obj = json.loads(line)
        assert "kind" in obj
        assert obj["kind"] == "message_part"
        assert "part" in obj


def test_stream_response_preserves_jsonrpc_id():
    """
    Scenario: /a2a/message/stream Preserves JSON-RPC ID in Each Event
    GIVEN a streaming request with JSON-RPC id
    WHEN events are streamed
    THEN each event includes the JSON-RPC envelope with same id
    """
    client = TestClient(app)
    payload = {
        "id": 999,
        "message": {
            "parts": [{"kind": "text", "text": "test"}]
        }
    }
    
    response = client.post("/a2a/message/stream", json=payload)
    lines = response.text.strip().split("\n")
    
    for line in lines:
        event = json.loads(line)
        assert "jsonrpc" in event
        assert event["jsonrpc"] == "2.0"
        assert "id" in event
        assert event["id"] == 999
        assert "result" in event


def test_jsonrpc_message_send_returns_task():
    """
    Scenario: JSON-RPC message/send Returns Task Structure
    GIVEN a JSON-RPC message/send request
    WHEN sent to the root endpoint
    THEN the response is a task with status
    """
    client = TestClient(app)
    payload = {
        "jsonrpc": "2.0",
        "id": 123,
        "method": "message/send",
        "params": {
            "message": {
                "parts": [{"kind": "text", "text": "test"}]
            }
        }
    }
    
    response = client.post("/", json=payload)
    assert response.status_code == 200
    
    result = response.json()
    assert result["jsonrpc"] == "2.0"
    assert result["id"] == 123
    
    task = result["result"]
    assert task["kind"] == "task"
    assert "id" in task
    assert "contextId" in task
    assert "status" in task
    
    status = task["status"]
    assert "state" in status
    assert status["state"] == "completed"
    assert "timestamp" in status
    assert "message" in status


def test_task_message_has_required_fields():
    """
    Scenario: Task Status Message Has Required Fields
    GIVEN a task returned from message/send
    WHEN examining the status.message
    THEN it contains kind, role, messageId, and parts
    """
    client = TestClient(app)
    payload = {
        "jsonrpc": "2.0",
        "id": 456,
        "method": "message/send",
        "params": {
            "message": {
                "parts": [{"kind": "text", "text": "test"}]
            }
        }
    }
    
    response = client.post("/", json=payload)
    task = response.json()["result"]
    message = task["status"]["message"]
    
    assert "kind" in message
    assert message["kind"] == "message"
    assert "role" in message
    assert message["role"] == "agent"
    assert "messageId" in message
    assert "parts" in message


def test_jsonrpc_invalid_method_returns_error():
    """
    Scenario: JSON-RPC Invalid Method Returns Error
    GIVEN a JSON-RPC request with unknown method
    WHEN sent to the root endpoint
    THEN it returns a JSON-RPC error with code -32601
    """
    client = TestClient(app)
    payload = {
        "jsonrpc": "2.0",
        "id": 789,
        "method": "unknown/method",
        "params": {}
    }
    
    response = client.post("/", json=payload)
    assert response.status_code == 400
    
    result = response.json()
    assert result["jsonrpc"] == "2.0"
    assert result["id"] == 789
    assert "error" in result
    
    error = result["error"]
    assert "code" in error
    assert error["code"] == -32601
    assert "message" in error
    assert "not found" in error["message"].lower()
