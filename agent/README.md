# AIBank Agent

FastAPI server that handles chat and A2A requests, routes them to banking tools, and returns A2UI template responses.

## Prerequisites

- Python 3.10+
- Dependencies installed: `pip install -r requirements.txt`

## Starting the server

Run from the **repository root** (not from inside `agent/`):

```bash
python3 -m uvicorn agent.agent:app --host 0.0.0.0 --port 8080
```

Check it is healthy:

```bash
curl http://127.0.0.1:8080/health
```

## Environment variables

Copy `.env.example` to `.env` and set values before starting:

```bash
cp agent/.env.example agent/.env
```

| Variable | Default | Description |
|---|---|---|
| `AGENT_RUNTIME` | `deterministic` | `deterministic` (no API key needed) or `adk` (uses Google ADK + LLM) |
| `LLM_MODEL` | `gpt-5-mini` | LLM model name used by the ADK runtime |
| `COPILOT_API_KEY` | — | API key required when `AGENT_RUNTIME=adk` |

> **Note:** the `deterministic` runtime uses keyword matching and mock data — no API key required. Use `adk` only when you want real LLM responses.

## API endpoints

| Method | Path | Description |
|---|---|---|
| `GET` | `/health` | Liveness check |
| `POST` | `/chat` | Simple chat — `{"message": "..."}` → `{text, a2ui, data}` |
| `POST` | `/a2a/message` | A2A non-streaming message |
| `POST` | `/a2a/message/stream` | A2A NDJSON streaming |
| `GET` | `/a2a/agent-card` | A2A agent capability card |
| `GET` | `/.well-known/agent-card.json` | Well-known agent card |
| `POST` | `/` | A2A JSON-RPC (`message/send`, `message/stream`) |

## Running tests

From the repository root:

```bash
python3 -m pytest agent/
```
