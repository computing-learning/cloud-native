import logging
import uuid

from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
logger = logging.getLogger("hub")

app = FastAPI(title="Ingress Agent Routing Lab Hub", version="1.0.0")


@app.middleware("http")
async def request_context(request: Request, call_next):
    request_id = request.headers.get("x-request-id", uuid.uuid4().hex)
    request.state.request_id = request_id
    response = await call_next(request)
    response.headers["x-request-id"] = request_id
    logger.info(
        "method=%s path=%s status=%s client=%s request_id=%s",
        request.method,
        request.url.path,
        response.status_code,
        request.client.host if request.client else "unknown",
        request_id,
    )
    return response


def envelope(request: Request, protocol: str, **extra):
    forwarded_for = request.headers.get("x-forwarded-for", "")
    request_id = getattr(request.state, "request_id", "")
    return {
        "service": "hub",
        "protocol": protocol,
        "method": request.method,
        "received_path": request.url.path,
        "forwarded_for": forwarded_for,
        "request_id": request_id,
        **extra,
    }


@app.get("/healthz")
async def healthz(request: Request):
    return envelope(request, "health", status="healthy")


@app.get("/api/status")
async def api_status(request: Request):
    return envelope(
        request,
        "rest",
        status="available",
        capabilities=["web-api", "mcp", "a2a"],
    )


@app.post("/api/mcp")
async def mcp(request: Request):
    body = await request.json()
    return envelope(
        request,
        "mcp-mock",
        jsonrpc="2.0",
        id=body.get("id"),
        result={"tools": [{"name": "echo", "description": "Mock tool"}]},
    )


@app.get("/api/a2a/agent-card.json")
async def agent_card(request: Request):
    return envelope(
        request,
        "a2a-agent-card-mock",
        name="Cloud Native Lab Agent",
        description="Mock A2A endpoint for ingress routing tests",
        url="http://gateway.local/api/a2a",
        capabilities={"streaming": False},
    )


@app.post("/api/a2a")
async def a2a(request: Request):
    body = await request.json()
    return envelope(
        request,
        "a2a-mock",
        result={"status": "completed", "echo": body},
    )


@app.exception_handler(404)
async def not_found(request: Request, _exception):
    return JSONResponse(
        status_code=404,
        content=envelope(request, "unknown", error="not_found"),
    )
