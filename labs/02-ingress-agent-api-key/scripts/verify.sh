#!/usr/bin/env bash

set -euo pipefail

kubectl apply --dry-run=server -f k8s/namespace.yaml
kubectl apply --dry-run=server -f k8s/api-key-auth.yaml
kubectl apply --dry-run=server -f k8s/hub.yaml
kubectl apply --dry-run=server -f k8s/frontend.yaml
kubectl apply --dry-run=server -f k8s/ingress.yaml

./external-agent/test-integration.sh
