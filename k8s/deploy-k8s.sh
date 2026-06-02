#!/bin/bash
# Build image, load into KIND, install ingress, deploy e-commerce app.
set -euo pipefail

CLUSTER_NAME="${CLUSTER_NAME:-ecommerce}"
IMAGE_NAME="${IMAGE_NAME:-ecommerce-app:1.0}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

echo "Building Docker image: ${IMAGE_NAME}"
docker build -t "$IMAGE_NAME" "$ROOT_DIR"

echo "Loading image into KIND cluster: ${CLUSTER_NAME}"
kind load docker-image "$IMAGE_NAME" --name "$CLUSTER_NAME"

echo "Installing ingress-nginx (if not present)..."
if ! kubectl get namespace ingress-nginx &>/dev/null; then
  kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.11.3/deploy/static/provider/kind/deploy.yaml
  kubectl wait --namespace ingress-nginx \
    --for=condition=ready pod \
    --selector=app.kubernetes.io/component=controller \
    --timeout=180s
fi

echo "Applying application manifests..."
kubectl label node "${CLUSTER_NAME}-control-plane" ingress-ready=true --overwrite 2>/dev/null || true

kubectl apply -f "${SCRIPT_DIR}/namespace.yaml"
kubectl apply -f "${SCRIPT_DIR}/deployment.yaml"
kubectl apply -f "${SCRIPT_DIR}/service.yaml"
kubectl apply -f "${SCRIPT_DIR}/ingress.yaml"

kubectl rollout status deployment/ecommerce-app -n ecommerce --timeout=120s

echo ""
echo "=========================================="
echo " Deployment: 2 replicas"
echo " Service:     ecommerce-service (ClusterIP :80)"
echo " Ingress:     http://localhost/"
echo "=========================================="
kubectl get pods,svc,ingress -n ecommerce
echo ""
echo "Open in browser: http://localhost/"
echo "Orders page:     http://localhost/orders"
