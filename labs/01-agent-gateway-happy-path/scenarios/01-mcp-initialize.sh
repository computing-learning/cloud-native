#!/usr/bin/env bash

set -euo pipefail

base_url="${BASE_URL:-http://127.0.0.1:8000}"
request_id="mcp-initialize-001"
response_file="$(mktemp)"

cleanup() {
  rm -f "$response_file"
}

trap cleanup EXIT

curl \
  --fail \
  --silent \
  --show-error \
  --request POST \
  --header 'Content-Type: application/json' \
  --header 'X-Agent-Api-Key: lab-agent-key' \
  --header "X-Request-Id: $request_id" \
  --data '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "initialize",
    "params": {
      "protocolVersion": "2025-06-18",
      "capabilities": {},
      "clientInfo": {
        "name": "integration-lab-client",
        "version": "1.0.0"
      }
    }
  }' \
  "$base_url/mcp" \
  > "$response_file"

python3 - "$response_file" "$request_id" <<'PY'
import json
import pathlib
import sys

response_file = pathlib.Path(sys.argv[1])
expected_request_id = sys.argv[2]
body = json.loads(response_file.read_text())

assert body["jsonrpc"] == "2.0"
assert body["id"] == 1
assert body["result"]["protocolVersion"] == "2025-06-18"
assert "tools" in body["result"]["capabilities"]
assert body["result"]["serverInfo"]["name"] == "agent-gateway-hub-mock"

meta = body["result"]["_meta"]

assert meta["service"] == "hub"
assert meta["protocol"] == "mcp"
assert meta["method"] == "initialize"
assert meta["received_path"] == "/mcp"
assert meta["request_id"] == expected_request_id

print(json.dumps(body, indent=2))
print("\nPASS: MCP initialize")
PY
