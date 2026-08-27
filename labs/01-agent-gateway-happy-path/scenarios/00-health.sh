#!/usr/bin/env bash

set -euo pipefail

base_url="${BASE_URL:-http://127.0.0.1:8000}"
request_id="health-scenario-001"

printf 'Scenario: Hub health\n'
printf 'Request: GET %s/healthz\n' "$base_url"
printf 'Request ID: %s\n\n' "$request_id"

response_file="$(mktemp)"
headers_file="$(mktemp)"

cleanup() {
  rm -f "$response_file" "$headers_file"
}

trap cleanup EXIT

status_code="$(
  curl \
    --silent \
    --show-error \
    --output "$response_file" \
    --dump-header "$headers_file" \
    --write-out '%{http_code}' \
    --header "X-Request-Id: $request_id" \
    "$base_url/healthz"
)"

if [[ "$status_code" != "200" ]]; then
  printf 'FAIL: expected HTTP 200, received %s\n' "$status_code" >&2
  cat "$response_file" >&2
  exit 1
fi

python3 - "$response_file" "$request_id" <<'PY'
import json
import pathlib
import sys

response_file = pathlib.Path(sys.argv[1])
expected_request_id = sys.argv[2]

body = json.loads(response_file.read_text())

assert body["service"] == "hub"
assert body["status"] == "healthy"
assert body["method"] == "GET"
assert body["received_path"] == "/healthz"
assert body["request_id"] == expected_request_id

print(json.dumps(body, indent=2))
PY

if ! grep -qi "^x-request-id: ${request_id}" "$headers_file"; then
  printf 'FAIL: response header X-Request-Id is missing\n' >&2
  exit 1
fi

printf '\nPASS: Hub health endpoint is reachable\n'
