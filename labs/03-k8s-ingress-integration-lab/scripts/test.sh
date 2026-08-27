#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${BASE_URL:-http://gateway.local}"
PASS_COUNT=0
FAIL_COUNT=0

run_test() {
  local name="$1" expected_status="$2" expected_text="$3"
  shift 3
  local body_file status
  body_file="$(mktemp)"
  status="$(curl -sS -o "$body_file" -w '%{http_code}' "$@")"
  if [[ "$status" == "$expected_status" ]] && grep -qF "$expected_text" "$body_file"; then
    echo "PASS: $name ($status)"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    echo "FAIL: $name (expected $expected_status and '$expected_text', got $status)"
    sed -n '1,20p' "$body_file"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
  rm -f "$body_file"
}

run_test "01 frontend" 200 "Frontend" "$BASE_URL/"
run_test "02 internal API" 200 '"received_path":"/users"' "$BASE_URL/api/users"
run_test "03 MCP valid key" 200 '"status":"ok"' -X POST "$BASE_URL/api/mcp" \
  -H 'Content-Type: application/json' -H 'x-hub-api-key: lab-hub-key' \
  -d '{"name":"get_status","input":{}}'
run_test "04 MCP wrong key" 401 "Invalid or missing" -X POST "$BASE_URL/api/mcp" \
  -H 'Content-Type: application/json' -H 'x-hub-api-key: wrong-key' \
  -d '{"name":"get_status","input":{}}'
run_test "05 A2A Agent Card" 200 '"url":"http://gateway.local/api/a2a"' \
  "$BASE_URL/.well-known/agent-card.json"
run_test "06 A2A JSON-RPC" 200 "Mock service is healthy" -X POST "$BASE_URL/api/a2a" \
  -H 'Content-Type: application/json' -H 'x-hub-api-key: lab-hub-key' \
  -d '{"jsonrpc":"2.0","id":"req-1","method":"message/send","params":{"message":{"messageId":"msg-1","role":"user","parts":[{"kind":"text","text":"Return service status"}]}}}'
run_test "07 key on internal API" 403 "403 Forbidden" "$BASE_URL/api/users" \
  -H 'x-hub-api-key: lab-hub-key'
run_test "08 internal API without key" 200 '"received_path":"/users"' "$BASE_URL/api/users"
run_test "09 unknown MCP path" 404 "Not Found" "$BASE_URL/api/mcp/unknown" \
  -H 'x-hub-api-key: lab-hub-key'
run_test "10 MCP missing key" 401 "Invalid or missing" -X POST "$BASE_URL/api/mcp" \
  -H 'Content-Type: application/json' -d '{"name":"get_status","input":{}}'

echo "$PASS_COUNT passed; $FAIL_COUNT failed"
[[ "$FAIL_COUNT" -eq 0 ]]
