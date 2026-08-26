#!/usr/bin/env bash

set -euo pipefail

base_url="${BASE_URL:-http://127.0.0.1:8080}"
response_file="$(mktemp)"

cleanup() {
  rm -f "$response_file"
}

trap cleanup EXIT

status_code="$(
  curl \
    --silent \
    --show-error \
    --output "$response_file" \
    --write-out '%{http_code}' \
    "$base_url/"
)"

if [[ "$status_code" != "200" ]]; then
  printf \
    'FAIL: expected HTTP 200, received %s\n' \
    "$status_code" \
    >&2

  exit 1
fi

if ! grep -q \
  'Cloud Native Ingress Routing Lab' \
  "$response_file"; then
  printf 'FAIL: expected frontend marker was not found\n' >&2
  exit 1
fi

if ! grep -q \
  'Frontend is reachable' \
  "$response_file"; then
  printf 'FAIL: expected status marker was not found\n' >&2
  exit 1
fi

printf 'PASS: frontend is reachable\n'
