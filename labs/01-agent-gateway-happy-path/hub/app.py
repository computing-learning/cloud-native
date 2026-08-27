import logging
import uuid

from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse

from hub.mcp import router as mcp_router


logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s level=%(levelname)s message=%(message)s",
)

logger = logging.getLogger("hub")

app = FastAPI(
    title="Agent Gateway Hub Mock",
    version="1.0.0",
)

app.include_router(mcp_router)


@app.middleware("http")
async def request_context(
    request: Request,
    call_next,
):
    request_id = request.headers.get("X-Request-Id")

    if not request_id:
        request_id = str(uuid.uuid4())

    request.state.request_id = request_id

    logger.info(
        "request_started request_id=%s method=%s path=%s client=%s",
        request_id,
        request.method,
        request.url.path,
        request.client.host if request.client else "unknown",
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
            "service": "hub",
            "status": "healthy",
            "method": request.method,
            "received_path": request.url.path,
            "request_id": request.state.request_id,
        },
    )
