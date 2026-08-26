#!/usr/bin/env bash

set -euo pipefail

expected_context="kind-agent-routing-lab"

manifest_url="$(
  printf '%s' \
    'https://raw.githubusercontent.com/' \
    'kubernetes/ingress-nginx/' \
    'controller-v1.15.1/' \
    'deploy/static/provider/kind/deploy.yaml'
)"

current_context="$(kubectl config current-context)"

if [[ "$current_context" != "$expected_context" ]]; then
  printf \
    'ERROR: expected context %s, current context is %s\n' \
    "$expected_context" \
    "$current_context" \
    >&2

  exit 1
fi

printf 'Installing ingress-nginx into %s\n' "$current_context"

kubectl apply \
  --server-side \
  --filename "$manifest_url"

printf 'Waiting for ingress-nginx controller\n'

kubectl rollout status \
  deployment/ingress-nginx-controller \
  --namespace ingress-nginx \
  --timeout=300s

kubectl get secret \
  ingress-nginx-admission \
  --namespace ingress-nginx \
  >/dev/null

kubectl get validatingwebhookconfiguration \
  ingress-nginx-admission \
  >/dev/null

printf 'ingress-nginx installation: READY\n'
