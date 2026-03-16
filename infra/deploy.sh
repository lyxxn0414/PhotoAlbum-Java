#!/bin/bash
# PhotoAlbum Azure Container Apps Deployment Script
# This script deploys the PhotoAlbum application to Azure Container Apps
# Prerequisites: Azure CLI installed and logged in, Docker installed

set -e

# Configuration
RESOURCE_GROUP="${RESOURCE_GROUP:-photoalbum-rg}"
LOCATION="${LOCATION:-eastus}"
APP_NAME="${APP_NAME:-photoalbum}"
IMAGE_TAG="${IMAGE_TAG:-latest}"

echo "=== PhotoAlbum Azure Deployment ==="
echo "Resource Group: $RESOURCE_GROUP"
echo "Location: $LOCATION"

# Check Azure CLI login
if ! az account show &>/dev/null; then
  echo "ERROR: Not logged in to Azure. Run 'az login' first."
  exit 1
fi

# Create resource group if it doesn't exist
echo "Creating resource group $RESOURCE_GROUP..."
az group create --name "$RESOURCE_GROUP" --location "$LOCATION" --output none

# Deploy infrastructure with Bicep
echo "Deploying infrastructure..."
# Use passwords from environment variables if provided, otherwise generate and
# store them in Azure Key Vault (created below). This prevents loss of credentials
# if the script is re-run. Export POSTGRES_ADMIN_PASSWORD and POSTGRES_APP_PASSWORD
# before running to supply your own values.
if [ -z "${POSTGRES_ADMIN_PASSWORD:-}" ]; then
  POSTGRES_ADMIN_PASSWORD=$(openssl rand -base64 20 | tr -d '/')
  echo "Generated POSTGRES_ADMIN_PASSWORD (store this securely)"
fi
if [ -z "${POSTGRES_APP_PASSWORD:-}" ]; then
  POSTGRES_APP_PASSWORD=$(openssl rand -base64 20 | tr -d '/')
  echo "Generated POSTGRES_APP_PASSWORD (store this securely)"
fi

DEPLOYMENT_OUTPUT=$(az deployment group create \
  --resource-group "$RESOURCE_GROUP" \
  --template-file "$(dirname "$0")/main.bicep" \
  --parameters "$(dirname "$0")/parameters.json" \
  --parameters postgresAdminPassword="$POSTGRES_ADMIN_PASSWORD" \
               postgresAppPassword="$POSTGRES_APP_PASSWORD" \
  --output json)

ACR_NAME=$(echo "$DEPLOYMENT_OUTPUT" | jq -r '.properties.outputs.acrName.value')
ACR_LOGIN_SERVER=$(echo "$DEPLOYMENT_OUTPUT" | jq -r '.properties.outputs.acrLoginServer.value')
CONTAINER_APP_URL=$(echo "$DEPLOYMENT_OUTPUT" | jq -r '.properties.outputs.containerAppUrl.value')

echo "ACR: $ACR_LOGIN_SERVER"
echo "App URL: $CONTAINER_APP_URL"

# Build and push Docker image
echo "Building Docker image..."
cd "$(dirname "$0")/.."
docker build -t "$ACR_LOGIN_SERVER/${APP_NAME}:${IMAGE_TAG}" .

echo "Logging in to ACR..."
az acr login --name "$ACR_NAME"

echo "Pushing image to ACR..."
docker push "$ACR_LOGIN_SERVER/${APP_NAME}:${IMAGE_TAG}"

# Update Container App to use the new image
echo "Updating Container App with new image..."
CONTAINER_APP_NAME=$(echo "$DEPLOYMENT_OUTPUT" | jq -r '.properties.outputs.containerAppName.value')
az containerapp update \
  --name "$CONTAINER_APP_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --image "$ACR_LOGIN_SERVER/${APP_NAME}:${IMAGE_TAG}" \
  --output none

echo "=== Deployment Complete ==="
echo "Application URL: $CONTAINER_APP_URL"
