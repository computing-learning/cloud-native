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

  LAST_STATUS="$(
    curl \
      --silent \
      --show-error \
      --output "${response_file}" \
      --write-out '%{http_code}' \
      --resolve "${HOST}:80:${INGRESS_IP}" \
      "$@"
  )"

  LAST_BODY="$(<"${response_file}")"
  rm -f "${response_file}"
}

assert_status() {
  local description="$1"
  local expected_status="$2"
  shift 2

  request "$@"

  if [[ "${LAST_STATUS}" == "${expected_status}" ]]; then
    echo "PASS: ${description} -> HTTP ${LAST_STATUS}"
    PASS_COUNT=$((PASS_COUNT + 1))
    return
  fi

  echo "FAIL: ${description}"
  echo "Expected status: ${expected_status}"
  echo "Actual status:   ${LAST_STATUS}"
  echo "Response body:   ${LAST_BODY}"

  FAIL_COUNT=$((FAIL_COUNT + 1))
}

assert_body_contains() {
  local description="$1"
  local expected_text="$2"

  if [[ "${LAST_BODY}" == *"${expected_text}"* ]]; then
    echo "PASS: ${description}"
    PASS_COUNT=$((PASS_COUNT + 1))
    return
  fi

  echo "FAIL: ${description}"
  echo "Expected body to contain: ${expected_text}"
  echo "Actual body: ${LAST_BODY}"

  FAIL_COUNT=$((FAIL_COUNT + 1))
}

echo "============================================================"
echo "Scenario 01 — MCP is exposed"
echo "============================================================"

assert_status \
  "External agent can call MCP" \
  "200" \
  --request POST \
  --header "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","id":1,"method":"tools/list"}' \
  "http://${HOST}/api/mcp"

assert_body_contains \
  "Hub receives /api/mcp without rewrite" \
  '"received_path":"/api/mcp"'

echo
echo "============================================================"
echo "Scenario 02 — A2A Agent Card is exposed"
echo "============================================================"

assert_status \
  "External agent can read the A2A Agent Card" \
  "200" \
  "http://${HOST}/api/a2a/agent-card.json"

assert_body_contains \
  "Hub receives the Agent Card path without rewrite" \
  '"received_path":"/api/a2a/agent-card.json"'

echo
echo "============================================================"
echo "Scenario 03 — A2A endpoint is exposed"
echo "============================================================"

assert_status \
  "External agent can call A2A" \
  "200" \
  --request POST \
  --header "Content-Type: application/json" \
  --data '{"message":"hello from external agent"}' \
  "http://${HOST}/api/a2a"

assert_body_contains \
  "Hub receives /api/a2a without rewrite" \
  '"received_path":"/api/a2a"'

echo
echo "============================================================"
echo "Scenario 04 — Frontend is protected"
echo "============================================================"

assert_status \
  "External agent cannot access frontend" \
  "403" \
  "http://${HOST}/"

echo
echo "============================================================"
echo "Scenario 05 — Internal REST API is protected"
echo "============================================================"

assert_status \
  "External agent cannot access status API" \
  "403" \
  "http://${HOST}/api/status"

assert_status \
  "External agent cannot access health API" \
  "403" \
  "http://${HOST}/api/healthz"

assert_status \
  "External agent cannot access unknown internal API" \
  "403" \
  "http://${HOST}/api/internal"

echo
echo "============================================================"
echo "Scenario 06 — Exact agent paths"
echo "============================================================"

assert_status \
  "MCP subpath is not exposed" \
  "403" \
  --request POST \
  --header "Content-Type: application/json" \
  --data '{}' \
  "http://${HOST}/api/mcp/tools"

assert_status \
  "Similar MCP path is not exposed" \
  "403" \
  --request POST \
  --header "Content-Type: application/json" \
  --data '{}' \
  "http://${HOST}/api/mcp-invalid"

assert_status \
  "A2A subpath is not exposed" \
  "403" \
  --request POST \
  --header "Content-Type: application/json" \
  --data '{}' \
  "http://${HOST}/api/a2a/tasks"

assert_status \
  "Similar A2A path is not exposed" \
  "403" \
  --request POST \
  --header "Content-Type: application/json" \
  --data '{}' \
  "http://${HOST}/api/a2a-invalid"

echo
echo "============================================================"
echo "Scenario 07 — Non-API Hub endpoints are not exposed"
echo "============================================================"

assert_status \
  "Hub health endpoint falls into protected frontend route" \
  "403" \
  "http://${HOST}/healthz"

assert_status \
  "Old MCP path is not exposed" \
  "403" \
  --request POST \
  --header "Content-Type: application/json" \
  --data '{}' \
  "http://${HOST}/mcp"

assert_status \
  "Old A2A path is not exposed" \
  "403" \
  --request POST \
  --header "Content-Type: application/json" \
  --data '{}' \
  "http://${HOST}/a2a"

assert_status \
  "Old Agent Card path is not exposed" \
  "403" \
  "http://${HOST}/agent-card.json"

echo
echo "============================================================"
echo "Test summary"
echo "============================================================"
echo "Passed: ${PASS_COUNT}"
echo "Failed: ${FAIL_COUNT}"

if (( FAIL_COUNT > 0 )); then
  exit 1
fi

echo
echo "All external-agent integration tests passed."
