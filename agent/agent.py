from __future__ import annotations

import json
import os
import sys
from pathlib import Path
from typing import Any

import jsonschema
from fastapi import FastAPI
from fastapi.responses import StreamingResponse
from pydantic import BaseModel

ROOT = Path(__file__).resolve().parent.parent
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from agent.a2ui_schema import A2UI_SCHEMA
from agent.runtime import RuntimeResponse, get_runtime

TEMPLATES_DIR = Path(__file__).parent / "templates"


class ChatRequest(BaseModel):
    message: str


class ChatResponse(BaseModel):
    text: str
    a2ui: list[dict[str, Any]]
    data: dict[str, Any]


class A2AStreamRequest(BaseModel):
    message: str | dict[str, Any] | None = None
    metadata: dict[str, Any] | None = None
    jsonrpc: str | None = None
    id: str | int | None = None
    method: str | None = None
    params: dict[str, Any] | None = None


def _load_template(name: str) -> list[dict[str, Any]]:
    with (TEMPLATES_DIR / name).open("r", encoding="utf-8") as f:
        payload = json.load(f)
    jsonschema.validate(instance=payload, schema=A2UI_SCHEMA)
    return payload


def handle_query(message: str) -> ChatResponse:
    runtime: RuntimeResponse = get_runtime().run(message)
    return ChatResponse(text=runtime.text, a2ui=_load_template(runtime.template_name), data=runtime.data)


def build_a2a_parts(response: ChatResponse) -> list[dict[str, Any]]:
    parts: list[dict[str, Any]] = [{"kind": "text", "text": response.text}]
    for message in response.a2ui:
        parts.append(
            {
                "kind": "data",
                "data": message,
                "metadata": {"mimeType": "application/json+a2ui"},
            }
        )
    return parts


def extract_a2a_user_text(payload: dict[str, Any]) -> str:
    direct = payload.get("message")
    if isinstance(direct, str) and direct.strip():
        return direct
    if isinstance(direct, dict):
        parts = direct.get("parts", [])
        for part in parts:
            if isinstance(part, dict) and part.get("kind") == "text":
                text = str(part.get("text", "")).strip()
                if text:
                    return text

    params = payload.get("params")
    if isinstance(params, dict):
        message = params.get("message", {})
        if isinstance(message, dict):
            parts = message.get("parts", [])
            for part in parts:
                if isinstance(part, dict) and part.get("kind") == "text":
                    text = str(part.get("text", "")).strip()
                    if text:
                        return text

    raise ValueError("No text message found in A2A payload")


def _message_envelope(parts: list[dict[str, Any]], request_id: str | int | None = None) -> dict[str, Any]:
    envelope = {"kind": "message", "parts": parts}
    if request_id is None:
        return envelope
    return {"jsonrpc": "2.0", "id": request_id, "result": envelope}


app = FastAPI(title="AIBank Agent")


@app.get("/health")
def health() -> dict[str, str]:
    return {
        "status": "ok",
        "model": os.getenv("LLM_MODEL", "gpt-5-mini"),
        "runtime": os.getenv("AGENT_RUNTIME", "deterministic"),
    }


@app.post("/chat", response_model=ChatResponse)
def chat(req: ChatRequest) -> ChatResponse:
    return handle_query(req.message)


@app.post("/a2a/message/stream")
def a2a_message_stream(req: A2AStreamRequest) -> StreamingResponse:
    payload = req.model_dump()
    message = extract_a2a_user_text(payload)
    response = handle_query(message)
    parts = build_a2a_parts(response)
    request_id = payload.get("id")

    def _iter_lines():
        for part in parts:
            event: dict[str, Any] = {"kind": "message_part", "part": part}
            if request_id is not None:
                event = {"jsonrpc": "2.0", "id": request_id, "result": event}
            yield json.dumps(event) + "\n"

    return StreamingResponse(_iter_lines(), media_type="application/x-ndjson")


@app.post("/a2a/message")
def a2a_message(req: A2AStreamRequest) -> dict[str, Any]:
    payload = req.model_dump()
    message = extract_a2a_user_text(payload)
    response = handle_query(message)
    return _message_envelope(build_a2a_parts(response), payload.get("id"))


@app.get("/a2a/agent-card")
def a2a_agent_card() -> dict[str, Any]:
    return {
        "name": "aibank-agent",
        "description": "Mock banking assistant with A2UI output",
        "capabilities": {
            "extensions": [
                {
                    "uri": "https://a2ui.org/a2a-extension/a2ui/v0.8",
                    "required": False,
                    "params": {
                        "supportedCatalogIds": [
                            "https://a2ui.org/specification/v0_8/standard_catalog_definition.json",
                            "https://aibank.local/catalogs/banking-v1.json",
                        ],
                        "acceptsInlineCatalogs": False,
                    },
                }
            ]
        },
    }
