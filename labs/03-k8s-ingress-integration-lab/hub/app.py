import os

from fastapi import Depends, FastAPI, Header, HTTPException

app = FastAPI(title="Mock Integration Hub")
EXPECTED_API_KEY = os.getenv("HUB_API_KEY", "lab-hub-key")


def require_api_key(x_hub_api_key: str | None = Header(default=None)) -> None:
    if x_hub_api_key != EXPECTED_API_KEY:
        raise HTTPException(status_code=401, detail="Invalid or missing x-hub-api-key")


def internal_response(path: str) -> dict:
    return {
        "service": "hub",
        "type": "internal-api",
        "method": "GET",
        "received_path": path,
    }


@app.get("/health")
def health() -> dict:
    return internal_response("/health")


@app.get("/users")
def users() -> dict:
    return internal_response("/users")


@app.get("/reports")
def reports() -> dict:
    return internal_response("/reports")


@app.get("/internal/status")
def internal_status() -> dict:
    return internal_response("/internal/status")


@app.get("/mcp/tools", dependencies=[Depends(require_api_key)])
def mcp_tools() -> dict:
    return {
        "tools": [
            {
                "name": "get_status",
                "description": "Return mock service status",
            }
        ]
    }


@app.post("/mcp", dependencies=[Depends(require_api_key)])
def mcp_call() -> dict:
    return {
        "content": [{"type": "json", "data": {"status": "ok"}}],
        "isError": False,
    }


@app.get("/.well-known/agent-card.json")
def agent_card() -> dict:
    return {
        "name": "Mock Integration Hub",
        "description": "Mock A2A endpoint for Kubernetes Ingress testing",
        "url": "http://gateway.local/api/a2a",
        "version": "0.1.0",
        "protocolVersion": "0.3.0",
        "preferredTransport": "JSONRPC",
        "capabilities": {"streaming": False},
    }


@app.post("/", dependencies=[Depends(require_api_key)])
def a2a_call(payload: dict) -> dict:
    return {
        "jsonrpc": "2.0",
        "id": payload.get("id"),
        "result": {
            "kind": "message",
            "messageId": "response-1",
            "role": "agent",
            "parts": [{"kind": "text", "text": "Mock service is healthy"}],
        },
    }
