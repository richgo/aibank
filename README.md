# AIBank

A demo AI-powered banking app. The backend agent serves banking data via a REST/A2A API; the Flutter app renders AI-generated UI using the GenUI/A2UI protocol.

## Architecture

```
mcp_server/   Banking data tools (mock accounts, transactions, mortgage, credit card)
agent/        FastAPI server — routes chat messages to the MCP tools and returns A2UI templates
app/          Flutter mobile/desktop app — sends messages and renders GenUI surfaces
```

## Quick Start

### 1. Start the agent backend

```bash
cd <repo root>
pip install -r agent/requirements.txt
python3 -m uvicorn agent.agent:app --host 0.0.0.0 --port 8080
```

Verify it is running:

```bash
curl http://127.0.0.1:8080/health
# {"status":"ok","model":"gpt-5-mini","runtime":"deterministic"}
```

### 2. Run the Flutter app

```bash
cd app
flutter pub get
flutter run          # pick a device when prompted, or pass -d <device-id>
```

The app connects to:
- **Android emulator** → `http://10.0.2.2:8080`
- **iOS simulator / desktop / web** → `http://127.0.0.1:8080`

The agent **must be running before you launch the app** or the first chat request will fail.

## Environment variables (agent)

Copy `agent/.env.example` to `agent/.env` and fill in values as needed.

| Variable | Default | Description |
|---|---|---|
| `AGENT_RUNTIME` | `deterministic` | Set to `adk` to use Google ADK + LLM |
| `LLM_MODEL` | `gpt-5-mini` | LLM model name (ADK runtime only) |
| `COPILOT_API_KEY` | — | API key for the LLM provider (ADK runtime) |

The default `deterministic` runtime requires no API key and works offline.

## Running tests

```bash
# Python (agent + mcp_server)
python3 -m pytest

# Flutter
cd app && flutter test
```

## Components

- [agent/README.md](agent/README.md) — agent server details
- [mcp_server/README.md](mcp_server/README.md) — MCP banking tools details
- [app/README.md](app/README.md) — Flutter app details
