# Infrastructure Rules Compliance Report

This document verifies compliance with all mandatory IaC rules for the Photo Album Azure infrastructure.

## General IaC Rules

| # | Rule | Status | Implementation |
|---|------|--------|----------------|
| 1 | Called `appmod-get-available-region-sku` to get available regions and SKUs | ✅ Applied | Region `swedencentral` selected from available regions with sufficient quota |
| 2 | Resource naming format: `az{resourcePrefix}{resourceToken}` | ✅ Applied | All resources use `az{prefix}{uniqueString(...)}` naming |
| 3 | Resource token uses `uniqueString(subscription().id, resourceGroup().id, location, environmentName)` | ✅ Applied | Defined in `main.bicep` variables section |
| 4 | Resource prefix ≤ 3 characters, alphanumeric only | ✅ Applied | Prefixes: log, id, cr, kv, pg, ce, ca |

## Deployment Tool Rules (azcli)

| # | Rule | Status | Implementation |
|---|------|--------|----------------|
| 1 | Use `.ps1` for PowerShell and `.sh` for Bash scripts | ✅ Applied | `deploy.ps1` and `deploy.sh` provided |
| 2 | Expected files: `main.bicep`, `main.parameters.json` | ✅ Applied | Both files generated in `./infra/` |

## Container Apps Rules

| # | Rule | Status | Implementation |
|---|------|--------|----------------|
| 1 | Attach User-Assigned Managed Identity | ✅ Applied | Container App uses `identity.type: 'UserAssigned'` with managed identity |
| 2 | AcrPull role assignment (7f951dda-...) to user-assigned managed identity | ✅ Applied | Role assignment defined in `main.bicep` before Container App |
| 3 | AcrPull role assignment defined BEFORE any container apps | ✅ Applied | Container App has `dependsOn: [acrPullRoleAssignment]` |
| 4 | Use user-assigned identity (NOT system) for container registry | ✅ Applied | Registry config uses `identity: managedIdentityId` |
| 5 | Container Apps use base image `mcr.microsoft.com/azuredocs/containerapps-helloworld:latest` | ✅ Applied | Set as default in `container-app.bicep` and `main.bicep` |
| 6 | Use `properties.configuration.registries` for ACR connection | ✅ Applied | Registry configured in container app module |
| 7 | Enable CORS via `properties.configuration.ingress.corsPolicy` | ✅ Applied | CORS policy with wildcard origins, methods, and headers |
| 8 | Container App Environment connected to Log Analytics Workspace | ✅ Applied | Uses `logAnalyticsConfiguration` with customerId and sharedKey |

## PostgreSQL Rules

| # | Rule | Status | Implementation |
|---|------|--------|----------------|
| 1 | Use version '17' or higher | ✅ Applied | `version: '17'` in postgresql module |
| 2 | Don't create database named 'postgres' | ✅ Applied | Database named `photoalbum` |
| 3 | Add firewall rule for Azure Services (0.0.0.0) | ✅ Applied | `AllowAzureServices` firewall rule with IP `0.0.0.0` |
| 4 | Use Managed Identity → Service Connector post-provision step | ✅ Applied | `deploy.ps1` and `deploy.sh` include Service Connector commands |
| 5 | Service Connector uses `--user-identity` (not `--system-identity`) | ✅ Applied | Uses `--user-identity client-id=... subs-id=...` |
| 6 | Service Connector uses `--client-type springBoot` | ✅ Applied | `--client-type springBoot` in both scripts |
| 7 | Service Connector uses `-c containername` for container app | ✅ Applied | `-c photoalbum` specified |
| 8 | For Spring Boot, don't add SPRING_DATASOURCE env vars in container app | ✅ Applied | Only `SPRING_PROFILES_ACTIVE=azure` env var set |

## Key Vault Rules

| # | Rule | Status | Implementation |
|---|------|--------|----------------|
| 1 | Use RBAC authentication | ✅ Applied | `enableRbacAuthorization: true` |
| 2 | Assign Key Vault Secrets Officer role (b86a8fe4-...) to managed identity | ✅ Applied | Role assignment in `key-vault.bicep` |
| 3 | Role assignment dependencies before secret access | ✅ Applied | Secrets depend on `kvSecretsOfficerRole` |
| 4 | Allow public access (publicNetworkAccess = Enabled) | ✅ Applied | `publicNetworkAccess: 'Enabled'` |

## Container Registry Rules

| # | Rule | Status | Implementation |
|---|------|--------|----------------|
| 1 | Admin user disabled | ✅ Applied | `adminUserEnabled: false` |
| 2 | AcrPull role for managed identity | ✅ Applied | Role assignment in `main.bicep` |

## Summary

- **Total rules evaluated**: 24
- **Rules applied**: 24 ✅
- **Rules skipped**: 0
- **Rules not applicable**: 0

All mandatory IaC rules have been implemented as specified.
