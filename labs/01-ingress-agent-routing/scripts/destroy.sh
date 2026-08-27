#!/usr/bin/env bash

set -euo pipefail

CLUSTER_NAME="agent-routing-lab"

if kind get clusters | grep -qx "${CLUSTER_NAME}"; then
  kind delete cluster --name "${CLUSTER_NAME}"
else
  echo "Cluster ${CLUSTER_NAME} does not exist."
fi

