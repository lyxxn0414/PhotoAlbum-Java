# Photo Album – Azure Container Apps Infrastructure

## Overview

This Bicep template provisions all Azure resources required to run the **Photo Album** Spring Boot application on Azure Container Apps.

## Provisioned Resources

| Resource | Type | SKU | Purpose |
|----------|------|-----|---------|
| `rg-photo-album-dev` | Resource Group | — | Container for all resources |
| `photoalbumacr<unique>` | Azure Container Registry | Basic | Store Docker images |
| `photo-album-logs-dev` | Log Analytics Workspace | PerGB2018 | ACA environment logging |
| `photo-album-mi-dev` | User-Assigned Managed Identity | — | Passwordless SQL auth |
| `photo-album-env-dev` | Container Apps Environment | Consumption | ACA runtime environment |
| `photo-album-dev` | Azure Container App | Consumption | Host the application |
| `photo-album-sqlserver-dev-<unique>` | Azure SQL Server | — | Database server |
| `photo-album-db` | Azure SQL Database | Basic (5 DTU) | Application database |

## Prerequisites

- Azure CLI 2.x installed and logged in (`az login`)
- Bicep CLI (installed automatically with Azure CLI 2.20+)
- Contributor role on the target subscription

## Quick Start

### Linux / macOS

```bash
chmod +x deploy-scripts/deploy.sh
./deploy-scripts/deploy.sh \
  rg-photo-album-dev \
  eastus \
  "<YOUR_SQL_ADMIN_PASSWORD>" \
  latest
```

### Windows (PowerShell)

```powershell
.\deploy-scripts\deploy.ps1 `
  -ResourceGroup "rg-photo-album-dev" `
  -Location "eastus" `
  -SqlAdminPassword "<YOUR_SQL_ADMIN_PASSWORD>" `
  -ImageTag "latest"
```

## Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `location` | `eastus` | Azure region for all resources |
| `appName` | `photoalbum` | Base name used for resource naming |
| `environmentName` | `dev` | Environment tag (dev / staging / prod) |
| `sqlAdminLogin` | `sqladmin` | SQL Server administrator login |
| `sqlAdminPassword` | — | SQL Server administrator password (required) |
| `imageTag` | `latest` | Docker image tag to deploy |

## Architecture

```
Internet
   │
   ▼
Azure Container App (photo-album-dev)
   │ port 8080 (HTTPS ingress)
   │ User-Assigned Managed Identity
   │
   ├─► Azure Container Registry (image pull)
   │
   └─► Azure SQL Database (ActiveDirectoryMSI authentication)
         └── Log Analytics Workspace (diagnostics)
```

## Environment Variables set on Container App

| Variable | Value |
|----------|-------|
| `SPRING_PROFILES_ACTIVE` | `azure` |
| `DATABASE_SERVER_HOST_NAME` | SQL Server FQDN |
| `DATABASE_NAME` | `photo-album-db` |
| `AZURE_MANAGED_IDENTITY_CLIENT_ID` | Managed Identity client ID |
| `JAVA_OPTS` | `-Xmx512m -Xms256m` |

## Scaling

- Min replicas: **1**
- Max replicas: **3**
- Scale rule: HTTP concurrency (10 concurrent requests per replica)

## Modules

| File | Description |
|------|-------------|
| `modules/logAnalytics.bicep` | Log Analytics Workspace |
| `modules/managedIdentity.bicep` | User-Assigned Managed Identity |
| `modules/containerRegistry.bicep` | Azure Container Registry |
| `modules/sqlServer.bicep` | Azure SQL Server + Database |
| `modules/containerAppsEnv.bicep` | Container Apps Environment |
| `modules/containerApp.bicep` | Container App + AcrPull role assignment |
