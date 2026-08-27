#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLUSTER_NAME="ingress-lab"

docker build -t ingress-lab-hub:latest "$ROOT_DIR/hub"
docker build -t ingress-lab-frontend:latest "$ROOT_DIR/frontend"
kind load docker-image ingress-lab-hub:latest --name "$CLUSTER_NAME"
kind load docker-image ingress-lab-frontend:latest --name "$CLUSTER_NAME"

kubectl apply -f "$ROOT_DIR/k8s/namespace.yaml"
kubectl apply -f "$ROOT_DIR/k8s/hub.yaml"
kubectl apply -f "$ROOT_DIR/k8s/frontend.yaml"
kubectl apply -f "$ROOT_DIR/k8s/ingress.yaml"
kubectl -n ingress-lab rollout status deployment/hub --timeout=120s
kubectl -n ingress-lab rollout status deployment/frontend --timeout=120s
kubectl -n ingress-lab get ingress,service,pod
