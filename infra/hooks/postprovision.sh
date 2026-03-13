#!/usr/bin/env sh
# ============================================================
# Post-provision hook: Wire up Azure Container App → PostgreSQL
# using Service Connector with User-Assigned Managed Identity
# (passwordless / Azure AD auth).
# ============================================================
set -e

echo "==> Installing Service Connector passwordless extension..."
az extension add --name serviceconnector-passwordless --upgrade --yes 2>/dev/null || true

echo "==> Creating Service Connector: Container App ↔ PostgreSQL (Spring Boot, Managed Identity)..."
az containerapp connection create postgres-flexible \
  --connection photoalbum-postgresql \
  --user-identity client-id="${MANAGED_IDENTITY_CLIENT_ID}" subs-id="${AZURE_SUBSCRIPTION_ID}" \
  --source-id "${CONTAINER_APP_RESOURCE_ID}" \
  --tg "${AZURE_RESOURCE_GROUP}" \
  --server "${POSTGRES_SERVER_NAME}" \
  --database "${POSTGRES_DATABASE_NAME}" \
  --client-type springBoot \
  -c photoalbum-java-app \
  -y

echo "==> Verifying Service Connector..."
az containerapp connection show \
  -g "${AZURE_RESOURCE_GROUP}" \
  -n "${AZURE_CONTAINER_APP_NAME}" \
  --connection photoalbum-postgresql \
  -o json

echo "==> Service Connector setup complete. SPRING_DATASOURCE_* env vars injected into Container App."
