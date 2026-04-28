#!/usr/bin/env bash
# deploy.sh – Deploy Photo Album to Azure Container Apps
# Usage: ./deploy.sh [RESOURCE_GROUP] [LOCATION] [SQL_ADMIN_PASSWORD] [IMAGE_TAG]
set -euo pipefail

# ── Configuration ─────────────────────────────────────────────────────────────
RESOURCE_GROUP="${1:-rg-photo-album-dev}"
LOCATION="${2:-eastus}"
SQL_ADMIN_PASSWORD="${3:-}"
IMAGE_TAG="${4:-latest}"
APP_NAME="photoalbum"
ENV_NAME="dev"
DEPLOYMENT_NAME="photo-album-deploy-$(date +%Y%m%d%H%M%S)"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Validate ──────────────────────────────────────────────────────────────────
if [[ -z "$SQL_ADMIN_PASSWORD" ]]; then
  echo "ERROR: SQL_ADMIN_PASSWORD is required as the 3rd argument." >&2
  exit 1
fi

command -v python3 >/dev/null 2>&1 || { echo "ERROR: python3 is required but not installed." >&2; exit 1; }

echo "=== Photo Album – Azure Container Apps Deployment ==="
echo "Resource Group : $RESOURCE_GROUP"
echo "Location       : $LOCATION"
echo "Image Tag      : $IMAGE_TAG"
echo ""

# ── Step 1 – Ensure AZ CLI is logged in ───────────────────────────────────────
echo "[1/7] Verifying Azure CLI login..."
az account show --output none
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
echo "      Subscription: $SUBSCRIPTION_ID"

# ── Step 2 – Create resource group ────────────────────────────────────────────
echo "[2/7] Creating resource group '$RESOURCE_GROUP'..."
az group create \
  --name "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --output none

# ── Step 3 – Deploy Bicep infrastructure ──────────────────────────────────────
echo "[3/7] Deploying Bicep infrastructure..."
BICEP_DIR="$(dirname "$SCRIPT_DIR")"
DEPLOY_OUTPUT=$(az deployment group create \
  --name "$DEPLOYMENT_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --template-file "$BICEP_DIR/main.bicep" \
  --parameters appName="$APP_NAME" \
               environmentName="$ENV_NAME" \
               location="$LOCATION" \
               sqlAdminLogin="sqladmin" \
               sqlAdminPassword="$SQL_ADMIN_PASSWORD" \
               imageTag="$IMAGE_TAG" \
  --output json)

ACR_NAME=$(echo "$DEPLOY_OUTPUT" | python3 -c "import sys,json; print(json.load(sys.stdin)['properties']['outputs']['acrName']['value'])")
ACR_LOGIN_SERVER=$(echo "$DEPLOY_OUTPUT" | python3 -c "import sys,json; print(json.load(sys.stdin)['properties']['outputs']['acrLoginServer']['value'])")
CONTAINER_APP_NAME=$(echo "$DEPLOY_OUTPUT" | python3 -c "import sys,json; print(json.load(sys.stdin)['properties']['outputs']['containerAppName']['value'])")
APP_FQDN=$(echo "$DEPLOY_OUTPUT" | python3 -c "import sys,json; print(json.load(sys.stdin)['properties']['outputs']['containerAppFqdn']['value'])" 2>/dev/null || echo "pending")

echo "      ACR            : $ACR_LOGIN_SERVER"
echo "      Container App  : $CONTAINER_APP_NAME"

# ── Step 4 – Build and push image to ACR ──────────────────────────────────────
echo "[4/7] Building and pushing Docker image to ACR..."
# Locate repo root by searching upward for Dockerfile
REPO_ROOT="$SCRIPT_DIR"
while [[ "$REPO_ROOT" != "/" && ! -f "$REPO_ROOT/Dockerfile" ]]; do
  REPO_ROOT="$(dirname "$REPO_ROOT")"
done
if [[ ! -f "$REPO_ROOT/Dockerfile" ]]; then
  echo "ERROR: Could not find Dockerfile from $SCRIPT_DIR upward." >&2
  exit 1
fi
az acr build \
  --registry "$ACR_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --image "photo-album:$IMAGE_TAG" \
  --file "$REPO_ROOT/Dockerfile" \
  "$REPO_ROOT"

# ── Step 5 – Update container app with new image ──────────────────────────────
echo "[5/7] Updating Container App with new image..."
az containerapp update \
  --name "$CONTAINER_APP_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --image "$ACR_LOGIN_SERVER/photo-album:$IMAGE_TAG" \
  --output none

# ── Step 6 – Wait for app to be running ──────────────────────────────────────
echo "[6/7] Waiting for Container App to reach Running state..."
for i in {1..20}; do
  STATUS=$(az containerapp show \
    --name "$CONTAINER_APP_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --query "properties.runningStatus" -o tsv 2>/dev/null || echo "Unknown")
  echo "      Attempt $i/20 – status: $STATUS"
  if [[ "$STATUS" == "Running" ]]; then
    break
  fi
  sleep 15
done

# ── Step 7 – Print summary ────────────────────────────────────────────────────
APP_FQDN=$(az containerapp show \
  --name "$CONTAINER_APP_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --query "properties.configuration.ingress.fqdn" -o tsv 2>/dev/null || echo "unavailable")

echo ""
echo "=== Deployment Complete ==="
echo "  Application URL : https://$APP_FQDN"
echo "  Resource Group  : $RESOURCE_GROUP"
echo "  Container App   : $CONTAINER_APP_NAME"
echo "  ACR             : $ACR_LOGIN_SERVER"
echo ""
echo "View logs:"
echo "  az containerapp logs show --name $CONTAINER_APP_NAME --resource-group $RESOURCE_GROUP --follow"
