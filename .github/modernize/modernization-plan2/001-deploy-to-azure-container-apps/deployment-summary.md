# Deployment Summary – Photo Album → Azure Container Apps

## Task
**ID**: `001-deploy-to-azure-container-apps`  
**Application**: Photo Album (Spring Boot 3.4.4 / Java 17)  
**Target**: Azure Container Apps (Consumption plan)

---

## Provisioned Azure Resources

| Resource | Name Pattern | SKU |
|----------|-------------|-----|
| Resource Group | `rg-photo-album-dev` | — |
| Azure Container Registry | `photoalbumacr<unique>` | Basic |
| Log Analytics Workspace | `photo-album-logs-dev` | PerGB2018 |
| User-Assigned Managed Identity | `photo-album-mi-dev` | — |
| Container Apps Environment | `photo-album-env-dev` | Consumption |
| Azure Container App | `photo-album-dev` | Consumption |
| Azure SQL Server | `photo-album-sqlserver-dev-<unique>` | — |
| Azure SQL Database | `photo-album-db` | Basic (5 DTU) |

---

## Deployment Artifacts

| File | Purpose |
|------|---------|
| `main.bicep` | Bicep entry point; orchestrates all modules |
| `parameters.json` | Default parameter values |
| `modules/logAnalytics.bicep` | Log Analytics Workspace |
| `modules/managedIdentity.bicep` | User-Assigned Managed Identity |
| `modules/containerRegistry.bicep` | Azure Container Registry |
| `modules/sqlServer.bicep` | Azure SQL Server + Database |
| `modules/containerAppsEnv.bicep` | Container Apps Environment |
| `modules/containerApp.bicep` | Container App + AcrPull role |
| `deploy-scripts/deploy.sh` | Linux/macOS deployment script |
| `deploy-scripts/deploy.ps1` | Windows deployment script |

---

## How to Deploy

```bash
# Linux / macOS
chmod +x deploy-scripts/deploy.sh
./deploy-scripts/deploy.sh rg-photo-album-dev eastus "<SQL_PASSWORD>"
```

```powershell
# Windows
.\deploy-scripts\deploy.ps1 -ResourceGroup rg-photo-album-dev -Location eastus -SqlAdminPassword "<SQL_PASSWORD>"
```

---

## Application Configuration

The Container App is configured with the `azure` Spring profile and the following environment variables:

| Variable | Description |
|----------|-------------|
| `SPRING_PROFILES_ACTIVE` | `azure` |
| `DATABASE_SERVER_HOST_NAME` | SQL Server FQDN (set from Bicep output) |
| `DATABASE_NAME` | `photo-album-db` |
| `AZURE_MANAGED_IDENTITY_CLIENT_ID` | MI client ID (set from Bicep output) |

---

## Validation Steps (Post-Deploy)

```bash
# Check container app status
az containerapp show --name photo-album-dev --resource-group rg-photo-album-dev --query "properties.runningStatus" -o tsv

# View application logs
az containerapp logs show --name photo-album-dev --resource-group rg-photo-album-dev --follow

# Open the app
APP_URL=$(az containerapp show --name photo-album-dev --resource-group rg-photo-album-dev --query "properties.configuration.ingress.fqdn" -o tsv)
echo "https://$APP_URL"
```
