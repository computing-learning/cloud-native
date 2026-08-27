#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLUSTER_NAME="ingress-lab"

kind create cluster --name "$CLUSTER_NAME" --config "$ROOT_DIR/kind-config.yaml"
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.13.2/deploy/static/provider/kind/deploy.yaml

# configuration-snippet is ingress-nginx-specific and disabled by default.
kubectl -n ingress-nginx patch configmap ingress-nginx-controller --type merge \
  -p '{"data":{"allow-snippet-annotations":"true","annotations-risk-level":"Critical"}}'
kubectl -n ingress-nginx rollout restart deployment ingress-nginx-controller
kubectl -n ingress-nginx rollout status deployment ingress-nginx-controller --timeout=180s

echo "Cluster ready. Add this once if gateway.local does not resolve:"
echo "127.0.0.1 gateway.local"
