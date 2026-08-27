#!/usr/bin/env bash

set -euo pipefail

CLUSTER_NAME="agent-routing-lab"

if kind get clusters | grep -qx "${CLUSTER_NAME}"; then
  echo "Cluster ${CLUSTER_NAME} already exists."
  exit 0
fi

kind create cluster --config k8s/kind-config.yaml
kubectl config use-context "kind-${CLUSTER_NAME}"

