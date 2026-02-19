from fastapi.testclient import TestClient

from agent.agent import app, build_a2a_parts, extract_a2a_user_text, handle_query


def test_build_a2a_parts_contains_a2ui_dataparts():
    response = handle_query('show my accounts')
    parts = build_a2a_parts(response)
    assert parts[0]['kind'] == 'text'
    data_parts = [p for p in parts if p['kind'] == 'data']
    assert data_parts
    assert all(p['metadata']['mimeType'] == 'application/json+a2ui' for p in data_parts)


def test_stream_endpoint_returns_ndjson_parts():
    client = TestClient(app)
    res = client.post('/a2a/message/stream', json={'message': 'show my accounts'})
    assert res.status_code == 200
    lines = [line for line in res.text.splitlines() if line.strip()]
    assert len(lines) >= 2
    assert 'application/json+a2ui' in res.text


def test_extract_a2a_user_text_from_envelope_parts():
    payload = {
        "params": {
            "message": {
                "parts": [{"kind": "text", "text": "show transactions"}],
            }
        }
    }
    assert extract_a2a_user_text(payload) == "show transactions"


def test_a2a_message_endpoint_returns_parts():
    client = TestClient(app)
    res = client.post(
        '/a2a/message',
        json={"message": {"parts": [{"kind": "text", "text": "show my accounts"}]}},
    )
    assert res.status_code == 200
    body = res.json()
    assert body["kind"] == "message"
    assert any(part.get("kind") == "data" for part in body["parts"])


def test_a2a_message_endpoint_returns_jsonrpc_envelope_when_id_present():
    client = TestClient(app)
    res = client.post(
        '/a2a/message',
        json={
            "jsonrpc": "2.0",
            "id": "req-1",
            "method": "message/send",
            "params": {"message": {"parts": [{"kind": "text", "text": "show my accounts"}]}},
        },
    )
    assert res.status_code == 200
    body = res.json()
    assert body["jsonrpc"] == "2.0"
    assert body["id"] == "req-1"
    assert body["result"]["kind"] == "message"


def test_stream_endpoint_returns_jsonrpc_events_when_id_present():
    client = TestClient(app)
    res = client.post(
        '/a2a/message/stream',
        json={
            "jsonrpc": "2.0",
            "id": "req-2",
            "method": "message/stream",
            "params": {"message": {"parts": [{"kind": "text", "text": "show my accounts"}]}},
        },
    )
    assert res.status_code == 200
    first_line = res.text.splitlines()[0]
    assert '"jsonrpc": "2.0"' in first_line
    assert '"id": "req-2"' in first_line


def test_a2a_agent_card_has_a2ui_extension():
    client = TestClient(app)
    res = client.get('/a2a/agent-card')
    assert res.status_code == 200
    body = res.json()
    ext = body["capabilities"]["extensions"][0]
    assert ext["uri"] == "https://a2ui.org/a2a-extension/a2ui/v0.8"
