#!/usr/bin/env bash

set -euo pipefail

EXPECTED_CONTEXT="kind-agent-routing-lab"
MANIFEST_URL="https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.15.1/deploy/static/provider/kind/deploy.yaml"

if [[ "$(kubectl config current-context)" != "${EXPECTED_CONTEXT}" ]]; then
  echo "ERROR: expected Kubernetes context ${EXPECTED_CONTEXT}"
  exit 1
fi

kubectl apply --server-side -f "${MANIFEST_URL}"

# Admission jobs may delete themselves immediately after completion, so the
# controller Deployment is the stable readiness condition.
kubectl rollout status deployment/ingress-nginx-controller \
  --namespace ingress-nginx --timeout 300s

kubectl get secret ingress-nginx-admission --namespace ingress-nginx
kubectl get validatingwebhookconfiguration ingress-nginx-admission

