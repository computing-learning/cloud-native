from typing import Any

from fastapi import APIRouter, Header, Request
from fastapi.responses import JSONResponse


router = APIRouter()

PROTOCOL_VERSION = "2025-06-18"
LAB_API_KEY = "lab-agent-key"


def jsonrpc_result(
    request_id: str | int,
    result: dict[str, Any],
) -> JSONResponse:
    return JSONResponse(
        status_code=200,
        content={
            "jsonrpc": "2.0",
            "id": request_id,
            "result": result,
        },
    )


def jsonrpc_error(
    request_id: str | int | None,
    code: int,
    message: str,
) -> JSONResponse:
    return JSONResponse(
        status_code=200,
        content={
            "jsonrpc": "2.0",
            "id": request_id,
            "error": {
                "code": code,
                "message": message,
            },
        },
    )


@router.post("/mcp")
async def handle_mcp(
    request: Request,
    x_agent_api_key: str | None = Header(default=None),
):
    if x_agent_api_key != LAB_API_KEY:
        return JSONResponse(
            status_code=401,
            content={
                "error": "unauthorized",
                "request_id": request.state.request_id,
            },
        )

    body = await request.json()

    request_id = body.get("id")
    method = body.get("method")
    params = body.get("params", {})

    if method == "initialize":
        client_version = params.get(
            "protocolVersion",
            PROTOCOL_VERSION,
        )

        negotiated_version = (
            client_version
            if client_version == PROTOCOL_VERSION
            else PROTOCOL_VERSION
        )

        return jsonrpc_result(
            request_id,
            {
                "protocolVersion": negotiated_version,
                "capabilities": {
                    "tools": {
                        "listChanged": False,
                    },
                },
                "serverInfo": {
                    "name": "agent-gateway-hub-mock",
                    "version": "1.0.0",
                },
                "instructions": (
                    "This is a deterministic MCP mock "
                    "for an infrastructure integration lab."
                ),
                "_meta": {
                    "service": "hub",
                    "protocol": "mcp",
                    "method": method,
                    "received_path": request.url.path,
                    "request_id": request.state.request_id,
                },
            },
        )

    return jsonrpc_error(
        request_id,
        -32601,
        f"Method not found: {method}",
    )
