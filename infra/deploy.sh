#!/bin/bash
set -euo pipefail

# ================================================
#  Photo Album - Azure Infrastructure Deployment
# ================================================

usage() {
    echo "Usage: $0 -e <environment-name> -g <resource-group> -p <postgres-admin-password> [-l <location>]"
    echo ""
    echo "Options:"
    echo "  -e    Environment name (e.g., dev, staging, prod)"
    echo "  -g    Resource group name"
    echo "  -p    PostgreSQL administrator password"
    echo "  -l    Azure region (default: swedencentral)"
    exit 1
}

LOCATION="swedencentral"

while getopts "e:g:p:l:" opt; do
    case $opt in
        e) ENVIRONMENT_NAME="$OPTARG" ;;
        g) RESOURCE_GROUP_NAME="$OPTARG" ;;
        p) POSTGRES_ADMIN_PASSWORD="$OPTARG" ;;
        l) LOCATION="$OPTARG" ;;
        *) usage ;;
    esac
done

if [[ -z "${ENVIRONMENT_NAME:-}" || -z "${RESOURCE_GROUP_NAME:-}" || -z "${POSTGRES_ADMIN_PASSWORD:-}" ]]; then
    echo "Error: Missing required parameters."
    usage
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "================================================"
echo " Photo Album - Azure Infrastructure Deployment"
echo "================================================"
echo ""

# Step 1: Create Resource Group
echo "[1/4] Creating resource group '$RESOURCE_GROUP_NAME' in '$LOCATION'..."
az group create --name "$RESOURCE_GROUP_NAME" --location "$LOCATION" --output none
echo "  Resource group created successfully."

# Step 2: Deploy Bicep template
echo "[2/4] Deploying Bicep infrastructure template..."
DEPLOYMENT_OUTPUT=$(az deployment group create \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --template-file "$SCRIPT_DIR/main.bicep" \
    --parameters environmentName="$ENVIRONMENT_NAME" \
                 location="$LOCATION" \
                 postgresAdminPassword="$POSTGRES_ADMIN_PASSWORD" \
    --query "properties.outputs" \
    --output json)

echo "  Infrastructure deployed successfully."

# Parse deployment outputs
CONTAINER_APP_NAME=$(echo "$DEPLOYMENT_OUTPUT" | jq -r '.containerAppName.value')
CONTAINER_REGISTRY_NAME=$(echo "$DEPLOYMENT_OUTPUT" | jq -r '.containerRegistryName.value')
CONTAINER_REGISTRY_LOGIN_SERVER=$(echo "$DEPLOYMENT_OUTPUT" | jq -r '.containerRegistryLoginServer.value')
POSTGRES_SERVER_NAME=$(echo "$DEPLOYMENT_OUTPUT" | jq -r '.postgresServerName.value')
POSTGRES_DATABASE_NAME=$(echo "$DEPLOYMENT_OUTPUT" | jq -r '.postgresDatabaseName.value')
MANAGED_IDENTITY_CLIENT_ID=$(echo "$DEPLOYMENT_OUTPUT" | jq -r '.managedIdentityClientId.value')
MANAGED_IDENTITY_NAME=$(echo "$DEPLOYMENT_OUTPUT" | jq -r '.managedIdentityName.value')
KEY_VAULT_NAME=$(echo "$DEPLOYMENT_OUTPUT" | jq -r '.keyVaultName.value')

echo ""
echo "  Deployment Outputs:"
echo "    Container App:      $CONTAINER_APP_NAME"
echo "    Container Registry: $CONTAINER_REGISTRY_LOGIN_SERVER"
echo "    PostgreSQL Server:  $POSTGRES_SERVER_NAME"
echo "    Database:           $POSTGRES_DATABASE_NAME"
echo "    Managed Identity:   $MANAGED_IDENTITY_NAME"
echo "    Key Vault:          $KEY_VAULT_NAME"
echo ""

# Step 3: Setup Service Connector for passwordless PostgreSQL
echo "[3/4] Setting up Service Connector for passwordless PostgreSQL..."
az extension add --name serviceconnector-passwordless --upgrade 2>/dev/null || true

SUBSCRIPTION_ID=$(az account show --query id -o tsv)

az containerapp connection create postgres-flexible \
    --connection photoalbum-db-connection \
    --source-id "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP_NAME/providers/Microsoft.App/containerApps/$CONTAINER_APP_NAME" \
    --target-id "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP_NAME/providers/Microsoft.DBforPostgreSQL/flexibleServers/$POSTGRES_SERVER_NAME/databases/$POSTGRES_DATABASE_NAME" \
    --user-identity client-id="$MANAGED_IDENTITY_CLIENT_ID" subs-id="$SUBSCRIPTION_ID" \
    --client-type springBoot \
    -c photoalbum \
    -y

echo "  Service Connector created successfully."

# Step 4: Summary
echo ""
echo "[4/4] Deployment Complete!"
echo "================================================"
echo " Infrastructure provisioned successfully!"
echo "================================================"
echo ""
echo "Resources created:"
echo "  - Container App:             $CONTAINER_APP_NAME"
echo "  - Container Registry:        $CONTAINER_REGISTRY_LOGIN_SERVER"
echo "  - PostgreSQL Flexible Server: $POSTGRES_SERVER_NAME"
echo "  - Database:                   $POSTGRES_DATABASE_NAME"
echo "  - Key Vault:                  $KEY_VAULT_NAME"
echo "  - Managed Identity:           $MANAGED_IDENTITY_NAME"
echo ""
echo "Next Steps:"
echo "  1. Build and push your container image:"
echo "     az acr build --registry $CONTAINER_REGISTRY_NAME --image photoalbum:latest ."
echo "  2. Update the container app with your image:"
echo "     az containerapp update --name $CONTAINER_APP_NAME --resource-group $RESOURCE_GROUP_NAME --image $CONTAINER_REGISTRY_LOGIN_SERVER/photoalbum:latest"
echo ""
