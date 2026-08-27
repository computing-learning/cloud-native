#!/usr/bin/env bash

set -euo pipefail

EXPECTED_CONTEXT="kind-agent-routing-lab"
CLUSTER_NAME="agent-routing-lab"
AUTH_IMAGE="ingress-api-key-auth:1.0.0"
HUB_IMAGE="ingress-routing-hub:1.0.0"
FRONTEND_IMAGE="ingress-routing-frontend:1.0.0"

if [[ "$(kubectl config current-context)" != "${EXPECTED_CONTEXT}" ]]; then
  echo "ERROR: expected Kubernetes context ${EXPECTED_CONTEXT}"
  exit 1
fi

docker build --tag "${AUTH_IMAGE}" api-key-auth
docker build --tag "${HUB_IMAGE}" hub
docker build --tag "${FRONTEND_IMAGE}" frontend

kind load docker-image "${AUTH_IMAGE}" --name "${CLUSTER_NAME}"
kind load docker-image "${HUB_IMAGE}" --name "${CLUSTER_NAME}"
kind load docker-image "${FRONTEND_IMAGE}" --name "${CLUSTER_NAME}"

kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/api-key-auth.yaml
kubectl apply -f k8s/hub.yaml
kubectl apply -f k8s/frontend.yaml

# Remove rules from earlier lab versions before installing the consolidated file.
kubectl delete ingress --namespace cloud-native-lab --all --ignore-not-found
kubectl apply --dry-run=server -f k8s/ingress.yaml
kubectl apply -f k8s/ingress.yaml

kubectl rollout restart deployment/api-key-auth deployment/hub deployment/frontend \
  --namespace cloud-native-lab
kubectl rollout status deployment/api-key-auth \
  --namespace cloud-native-lab --timeout 180s
kubectl rollout status deployment/hub \
  --namespace cloud-native-lab --timeout 180s
kubectl rollout status deployment/frontend \
  --namespace cloud-native-lab --timeout 180s

kubectl get pods,services,ingress --namespace cloud-native-lab
