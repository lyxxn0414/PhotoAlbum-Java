# Photo Album - Azure Infrastructure

## Overview

This directory contains Bicep Infrastructure as Code (IaC) files for provisioning the Photo Album application on Azure.

## Architecture

The infrastructure deploys the following Azure resources:

| Resource | Type | Purpose |
|----------|------|---------|
| **Container App** | Microsoft.App/containerApps | Hosts the Photo Album Spring Boot application (1.0 CPU, 2Gi RAM, health probes) |
| **Container Apps Environment** | Microsoft.App/managedEnvironments | Managed hosting environment for Container Apps |
| **Container Registry** | Microsoft.ContainerRegistry/registries | Stores Docker container images |
| **PostgreSQL Flexible Server** | Microsoft.DBforPostgreSQL/flexibleServers | Managed PostgreSQL database |
| **Key Vault** | Microsoft.KeyVault/vaults | Stores secrets (PostgreSQL admin credentials) |
| **User-Assigned Managed Identity** | Microsoft.ManagedIdentity/userAssignedIdentities | Passwordless authentication to ACR and PostgreSQL |
| **Log Analytics Workspace** | Microsoft.OperationalInsights/workspaces | Centralized logging and monitoring |

## Directory Structure

```
infra/
├── main.bicep                              # Main orchestration template
├── main.parameters.json                    # Environment-specific parameters
├── modules/
│   ├── log-analytics.bicep                 # Log Analytics Workspace module
│   ├── managed-identity.bicep              # User-Assigned Managed Identity module
│   ├── container-registry.bicep            # Azure Container Registry module
│   ├── key-vault.bicep                     # Azure Key Vault module
│   ├── postgresql.bicep                    # PostgreSQL Flexible Server module
│   ├── container-app-environment.bicep     # Container Apps Environment module
│   └── container-app.bicep                 # Container App module
├── deploy.ps1                              # PowerShell deployment script (Windows)
├── deploy.sh                               # Bash deployment script (Linux/macOS)
├── README.md                               # This file
└── compliance.md                           # Rules compliance report
```

## Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `environmentName` | string | *(required)* | Environment name (e.g., dev, staging, prod) |
| `location` | string | `swedencentral` | Azure region for deployment |
| `postgresAdminLogin` | string | `pgadmin` | PostgreSQL administrator login |
| `postgresAdminPassword` | securestring | *(required)* | PostgreSQL administrator password |
| `postgresDatabaseName` | string | `photoalbum` | Name of the PostgreSQL database |

## Prerequisites

- [Azure CLI](https://docs.microsoft.com/cli/azure/install-azure-cli) (v2.50+)
- [Bicep CLI](https://learn.microsoft.com/azure/azure-resource-manager/bicep/install) (included with Azure CLI)
- An active Azure subscription
- Logged in to Azure CLI: `az login`

## Deployment

### Windows (PowerShell)

```powershell
.\deploy.ps1 -EnvironmentName "dev" `
             -ResourceGroupName "rg-photoalbum-dev" `
             -PostgresAdminPassword (Read-Host -AsSecureString "Enter PostgreSQL password")
```

### Linux/macOS (Bash)

```bash
chmod +x deploy.sh
./deploy.sh -e dev -g rg-photoalbum-dev -p "YourSecurePassword123!"
```

## Post-Deployment

After infrastructure provisioning, the deployment scripts automatically:

1. **Create a Service Connector** for passwordless PostgreSQL authentication using Managed Identity
2. Set the client type to `springBoot` so Spring Boot connection properties are auto-configured

### Build and Deploy Application

After infrastructure is provisioned:

```bash
# Build container image in ACR
az acr build --registry <registry-name> --image photoalbum:latest .

# Update Container App with the built image
az containerapp update \
    --name <container-app-name> \
    --resource-group <resource-group-name> \
    --image <registry-login-server>/photoalbum:latest
```

## Authentication

- **Container Registry**: Container App uses User-Assigned Managed Identity with AcrPull role (scoped to ACR)
- **PostgreSQL**: Passwordless authentication via Azure Managed Identity using Service Connector
- **Key Vault**: RBAC-based access with Key Vault Secrets Officer role assigned to Managed Identity

## Health Probes

The Container App is configured with health probes for the Spring Boot Actuator endpoints:

| Probe Type | Path | Initial Delay | Period |
|------------|------|---------------|--------|
| **Startup** | `/actuator/health` | 10s | 10s |
| **Liveness** | `/actuator/health/liveness` | 30s | 30s |
| **Readiness** | `/actuator/health/readiness` | 15s | 10s |

## Resource Naming Convention

All resources follow the naming pattern: `az{prefix}{resourceToken}`

| Prefix | Resource |
|--------|----------|
| `log` | Log Analytics Workspace |
| `id` | User-Assigned Managed Identity |
| `cr` | Container Registry |
| `kv` | Key Vault |
| `pg` | PostgreSQL Flexible Server |
| `ce` | Container Apps Environment |
| `ca` | Container App |

Where `resourceToken` = `uniqueString(subscription().id, resourceGroup().id, location, environmentName)`

## Security

- All secrets stored in Azure Key Vault
- Managed Identity used for service-to-service authentication (no passwords in code)
- PostgreSQL firewall configured to allow only Azure services
- Container Registry admin user disabled (uses RBAC)
- Key Vault uses RBAC authentication model
- CORS policy configured on Container App ingress
