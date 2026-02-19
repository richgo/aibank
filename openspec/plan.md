# Implementation Plan

## Completed
- Scaffolded `app/`, `agent/`, and `mcp_server/`.
- Implemented MCP mock banking tools and fixture data.
- Implemented A2UI template/schema validation and response assembly.
- Added A2A-style endpoints:
  - `POST /a2a/message/stream` (NDJSON streaming parts)
  - `POST /a2a/message` (message envelope)
  - `GET /a2a/agent-card` (A2UI extension metadata)
- Added JSON-RPC-compatible request/response handling (`id`, `jsonrpc`, `params.message.parts`).
- Refactored agent execution into runtime abstraction and implemented:
  - `DeterministicRuntime` (default)
  - `ADKRuntime` (ADK runner + tool wiring + strict JSON output parsing)
- Implemented Flutter GenUI chat shell and banking catalog components.
- Added/expanded Python and Flutter tests (A2A envelope, runtime behavior, MCP tools, templates, widgets).

## Validation Status
- Python: `19 passed`.
- Flutter: `All tests passed`.

## Next Steps
- Run and verify `AGENT_RUNTIME=adk` against a configured GPT-5 mini-backed ADK environment.
- Add integration tests that exercise ADK runtime with a real model response contract.
- Tighten A2A contract fields further to exactly match your target orchestrator/client implementation.
