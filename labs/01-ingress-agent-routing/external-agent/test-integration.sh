#!/usr/bin/env bash

set -euo pipefail

HOST="gateway.local"
INGRESS_IP="${INGRESS_IP:-127.0.0.1}"
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

assert_body() {
  local description="$1"
  local expected="$2"
  if [[ "${LAST_BODY}" == *"${expected}"* ]]; then
    echo "PASS: ${description}"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    echo "FAIL: ${description}; missing ${expected}"
    echo "Body: ${LAST_BODY}"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
}

echo "Allowed integration endpoints"

assert_status "MCP is exposed" 200 --request POST \
  --header 'Content-Type: application/json' \
  --data '{"jsonrpc":"2.0","id":1,"method":"tools/list"}' \
  "http://${HOST}/api/mcp"
assert_body "MCP path is not rewritten" '"received_path":"/api/mcp"'

assert_status "Agent Card is exposed" 200 \
  "http://${HOST}/api/a2a/agent-card.json"
assert_body "Agent Card path is not rewritten" \
  '"received_path":"/api/a2a/agent-card.json"'

assert_status "A2A is exposed" 200 --request POST \
  --header 'Content-Type: application/json' \
  --data '{"message":"hello from external agent"}' \
  "http://${HOST}/api/a2a"
assert_body "A2A path is not rewritten" '"received_path":"/api/a2a"'

echo
echo "Denied internal surface"

assert_status "Frontend is denied" 403 "http://${HOST}/"
assert_status "Internal status API is denied" 403 "http://${HOST}/api/status"
assert_status "Unknown internal API is denied" 403 "http://${HOST}/api/internal"

echo
echo "Exact-path boundaries"

assert_status "MCP child path is denied" 403 --request POST \
  --header 'Content-Type: application/json' --data '{}' \
  "http://${HOST}/api/mcp/tools"
assert_status "Similar MCP path is denied" 403 --request POST \
  --header 'Content-Type: application/json' --data '{}' \
  "http://${HOST}/api/mcp-invalid"
assert_status "A2A child path is denied" 403 --request POST \
  --header 'Content-Type: application/json' --data '{}' \
  "http://${HOST}/api/a2a/tasks"
assert_status "Direct health endpoint is denied" 403 \
  "http://${HOST}/healthz"

echo
echo "Passed: ${PASS_COUNT}"
echo "Failed: ${FAIL_COUNT}"

if ((FAIL_COUNT > 0)); then
  exit 1
fi

echo "All integration tests passed."

