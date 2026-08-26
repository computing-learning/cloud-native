#!/usr/bin/env bash

set -euo pipefail

base_url="${BASE_URL:-http://127.0.0.1:8000}"

request() {
  local name="$1"
  shift

  printf '\n=== %s ===\n' "$name"
  curl \
    --fail \
    --silent \
    --show-error \
    "$@" \
    | python3 -m json.tool
}

request \
  "Health" \
  --header 'X-Request-Id: local-health-001' \
  "$base_url/healthz"

request \
  "Web API" \
  --header 'X-Request-Id: local-api-001' \
  "$base_url/api/status"

request \
  "MCP mock" \
  --request POST \
  --header 'Content-Type: application/json' \
  --header 'X-Request-Id: local-mcp-001' \
  --data '{"message":"hello mcp"}' \
  "$base_url/mcp"

request \
  "A2A Agent Card" \
  --header 'X-Request-Id: local-agent-card-001' \
  "$base_url/agent-card.json"

request \
  "A2A mock" \
  --request POST \
  --header 'Content-Type: application/json' \
  --header 'X-Request-Id: local-a2a-001' \
  --data '{"message":"hello a2a"}' \
  "$base_url/a2a"

printf '\nPASS: all local Hub endpoints are reachable\n'
