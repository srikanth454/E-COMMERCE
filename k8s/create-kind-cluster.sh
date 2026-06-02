#!/bin/bash
# Create a single-node KIND cluster on the local machine.
set -euo pipefail

CLUSTER_NAME="${CLUSTER_NAME:-ecommerce}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="${SCRIPT_DIR}/kind-config.yaml"

if kind get clusters 2>/dev/null | grep -qx "$CLUSTER_NAME"; then
  echo "Cluster '${CLUSTER_NAME}' already exists."
  kubectl cluster-info --context "kind-${CLUSTER_NAME}"
  kubectl get nodes --context "kind-${CLUSTER_NAME}"
  exit 0
fi

kind create cluster --name "$CLUSTER_NAME" --config "$CONFIG" --wait 10m
kubectl cluster-info --context "kind-${CLUSTER_NAME}"
kubectl get nodes --context "kind-${CLUSTER_NAME}"

echo ""
echo "Cluster ready. Context: kind-${CLUSTER_NAME}"
