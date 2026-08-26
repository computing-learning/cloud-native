import logging
import uuid
from typing import Any

from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse


logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s level=%(levelname)s message=%(message)s",
)

logger = logging.getLogger("hub")

PUBLIC_A2A_URL = "http://gateway.local/agent/a2a"

app = FastAPI(
    title="Ingress Routing Hub Mock",
    version="1.0.0",
)


def request_metadata(
    request: Request,
    protocol: str,
) -> dict[str, str]:
    return {
        "service": "hub",
        "protocol": protocol,
        "method": request.method,
        "received_path": request.url.path,
        "request_id": request.state.request_id,
    }


@app.middleware("http")
async def add_request_context(
    request: Request,
    call_next,
):
    request_id = request.headers.get("X-Request-Id")

    if not request_id:
        request_id = str(uuid.uuid4())

    request.state.request_id = request_id

    logger.info(
        "request_started request_id=%s method=%s path=%s",
        request_id,
        request.method,
        request.url.path,
    )

    response = await call_next(request)

    response.headers["X-Request-Id"] = request_id

    logger.info(
        "request_completed request_id=%s method=%s path=%s status=%s",
        request_id,
        request.method,
        request.url.path,
        response.status_code,
    )

    return response


@app.get("/healthz")
async def healthz(request: Request):
    return JSONResponse(
        status_code=200,
        content={
            **request_metadata(request, "http"),
            "status": "healthy",
        },
    )


@app.get("/api/status")
async def api_status(request: Request):
    return JSONResponse(
        status_code=200,
        content={
            **request_metadata(request, "rest"),
            "status": "available",
            "capabilities": [
                "web-api",
                "mcp",
                "a2a",
            ],
        },
    )


@app.post("/mcp")
async def mcp_mock(
    request: Request,
):
    body: dict[str, Any] = await request.json()

    return JSONResponse(
        status_code=200,
        content={
            **request_metadata(request, "mcp-mock"),
            "status": "accepted",
            "input": body,
        },
    )


@app.get("/agent-card.json")
async def agent_card(request: Request):
    return JSONResponse(
        status_code=200,
        content={
            "name": "Hub Mock Agent",
            "description": (
                "A deterministic mock agent used to verify "
                "Kubernetes Ingress routing."
            ),
            "url": PUBLIC_A2A_URL,
            "capabilities": [
                "mock-task",
            ],
            "_debug": request_metadata(
                request,
                "a2a-agent-card-mock",
            ),
        },
    )


@app.post("/a2a")
async def a2a_mock(
    request: Request,
):
    body: dict[str, Any] = await request.json()

    return JSONResponse(
        status_code=200,
        content={
            **request_metadata(request, "a2a-mock"),
            "status": "completed",
            "result": {
                "message": "Mock A2A request completed",
                "input": body,
            },
        },
    )
