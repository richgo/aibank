from __future__ import annotations

import json
import os
import sys
import time
import uuid
from pathlib import Path
from typing import Any

import jsonschema
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi import Request
from fastapi.responses import JSONResponse
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
    a2ui = _load_template(runtime.template_name)
    surface_id = str(uuid.uuid4())
    for item in a2ui:
        for message_key in ("surfaceUpdate", "dataModelUpdate", "beginRendering"):
            payload = item.get(message_key)
            if isinstance(payload, dict):
                payload["surfaceId"] = surface_id
        update = item.get("dataModelUpdate")
        if isinstance(update, dict):
            # Pass data as a dict so DataModel uses its permissive Map path
            # (_parseDataModelContents expects {key,valueString} format which
            # is complex; the Map path sets _data = runtime.data directly).
            update["contents"] = runtime.data
    return ChatResponse(text=runtime.text, a2ui=a2ui, data=runtime.data)


def build_a2a_parts(response: ChatResponse) -> list[dict[str, Any]]:
    parts: list[dict[str, Any]] = []
    if response.text.strip():
        parts.append({"kind": "text", "text": response.text})
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


def _a2a_parts(response: ChatResponse) -> list[dict[str, Any]]:
    return build_a2a_parts(response)


def _a2a_message(response: ChatResponse) -> dict[str, Any]:
    return {
        "kind": "message",
        "role": "agent",
        "messageId": str(uuid.uuid4()),
        "parts": _a2a_parts(response),
    }


def _a2a_task(response: ChatResponse, task_id: str, context_id: str) -> dict[str, Any]:
    return {
        "id": task_id,
        "contextId": context_id,
        "kind": "task",
        "status": {
            "state": "completed",
            "timestamp": str(int(time.time() * 1000)),
            "message": _a2a_message(response),
        },
    }


app = FastAPI(title="AIBank Agent")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


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
                            "https://aibank.local/catalogs/googlemaps-v1.json",
                        ],
                        "acceptsInlineCatalogs": False,
                    },
                }
            ]
        },
    }


@app.get("/.well-known/agent-card.json")
def a2a_agent_card_well_known(request: Request) -> dict[str, Any]:
    card = a2a_agent_card()
    card["url"] = str(request.base_url).rstrip("/")
    card["capabilities"]["streaming"] = True
    return card


@app.post("/")
async def a2a_rpc(req: Request):
    payload = await req.json()
    request_id = payload.get("id")
    method = payload.get("method")
    
    # Check method first before attempting to extract text
    if method not in ["message/send", "message/stream"]:
        return JSONResponse(
            {
                "jsonrpc": "2.0",
                "id": request_id,
                "error": {"code": -32601, "message": f"Method not found: {method}"},
            },
            status_code=400,
        )
    
    params = payload.get("params", {}) if isinstance(payload.get("params"), dict) else {}
    msg = params.get("message", {}) if isinstance(params, dict) else {}
    
    try:
        text = extract_a2a_user_text({"message": msg})
    except ValueError as exc:
        return JSONResponse(
            {
                "jsonrpc": "2.0",
                "id": request_id,
                "error": {"code": -32602, "message": f"Invalid params: {exc}"},
            },
            status_code=400,
        )
    
    response = handle_query(text)

    if method == "message/send":
        task_id = str(uuid.uuid4())
        context_id = str(uuid.uuid4())
        return JSONResponse({"jsonrpc": "2.0", "id": request_id, "result": _a2a_task(response, task_id, context_id)})

    if method == "message/stream":
        task_id = str(uuid.uuid4())
        context_id = str(uuid.uuid4())
        task = _a2a_task(response, task_id, context_id)

        def _sse():
            yield f"data: {json.dumps({'jsonrpc': '2.0', 'id': request_id, 'result': task})}\n\n"

        return StreamingResponse(_sse(), media_type="text/event-stream")
