#!/usr/bin/env bash

set -euo pipefail

HOST="gateway.local"
INGRESS_IP="${INGRESS_IP:-127.0.0.1}"
API_KEY="${API_KEY:-lab-agent-key}"
PASS_COUNT=0
FAIL_COUNT=0
LAST_STATUS=""
LAST_BODY=""

request() {
  local response_file
  response_file="$(mktemp)"
  LAST_STATUS="$(curl --silent --show-error --output "${response_file}" \
    --write-out '%{http_code}' --resolve "${HOST}:80:${INGRESS_IP}" "$@")"
  LAST_BODY="$(<"${response_file}")"
  rm -f "${response_file}"
}

assert_status() {
  local description="$1"
  local expected="$2"
  shift 2
  request "$@"
  if [[ "${LAST_STATUS}" == "${expected}" ]]; then
    echo "PASS: ${description} -> HTTP ${LAST_STATUS}"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    echo "FAIL: ${description}; expected ${expected}, got ${LAST_STATUS}"
    echo "Body: ${LAST_BODY}"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
}

echo "Scenario 01 — valid key"

assert_status "MCP accepts valid key" 200 --request POST \
  --header "X-API-Key: ${API_KEY}" \
  --header 'Content-Type: application/json' \
  --data '{"jsonrpc":"2.0","id":1,"method":"tools/list"}' \
  "http://${HOST}/api/mcp"

assert_status "A2A accepts valid key" 200 --request POST \
  --header "X-API-Key: ${API_KEY}" \
  --header 'Content-Type: application/json' \
  --data '{"message":"hello"}' \
  "http://${HOST}/api/a2a"

assert_status "Agent Card accepts valid key" 200 \
  --header "X-API-Key: ${API_KEY}" \
  "http://${HOST}/api/a2a/agent-card.json"

echo
echo "Scenario 02 — missing key"

assert_status "MCP rejects missing key" 401 --request POST \
  --header 'Content-Type: application/json' --data '{}' \
  "http://${HOST}/api/mcp"
assert_status "A2A rejects missing key" 401 --request POST \
  --header 'Content-Type: application/json' --data '{}' \
  "http://${HOST}/api/a2a"
assert_status "Agent Card rejects missing key" 401 \
  "http://${HOST}/api/a2a/agent-card.json"

echo
echo "Scenario 03 — invalid key"

assert_status "MCP rejects invalid key" 401 --request POST \
  --header 'X-API-Key: wrong-key' \
  --header 'Content-Type: application/json' --data '{}' \
  "http://${HOST}/api/mcp"

echo
echo "Scenario 04 — broad routes remain unchanged"

assert_status "Frontend does not require agent key" 200 \
  "http://${HOST}/"
assert_status "Internal status API does not require agent key" 200 \
  "http://${HOST}/api/status"

echo
echo "Scenario 05 — exact path boundary"

assert_status "MCP child path is not an agent endpoint" 404 --request POST \
  --header 'Content-Type: application/json' --data '{}' \
  "http://${HOST}/api/mcp/tools"

echo
echo "Passed: ${PASS_COUNT}"
echo "Failed: ${FAIL_COUNT}"

if ((FAIL_COUNT > 0)); then
  exit 1
fi

echo "All integration tests passed."
