import hmac
import os

from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse, Response

app = FastAPI(title="Agent API Key Auth", version="1.0.0")
EXPECTED_API_KEY = os.environ["AGENT_API_KEY"]


@app.get("/healthz")
async def healthz():
    return {"status": "healthy"}


@app.get("/authorize")
async def authorize(request: Request):
    supplied_key = request.headers.get("x-api-key", "")

    if not supplied_key:
        return JSONResponse(status_code=401, content={"error": "missing_api_key"})

    if not hmac.compare_digest(supplied_key, EXPECTED_API_KEY):
        return JSONResponse(status_code=401, content={"error": "invalid_api_key"})

    return Response(status_code=200)
