<#
.SYNOPSIS
    Deploys the Photo Album Azure infrastructure using Bicep templates.

.DESCRIPTION
    This script provisions all Azure resources for the Photo Album application including:
    - Azure Container Apps with Container Apps Environment
    - Azure Container Registry
    - Azure Database for PostgreSQL Flexible Server
    - Azure Key Vault
    - User-Assigned Managed Identity
    - Log Analytics Workspace

    After provisioning, it creates a Service Connector for passwordless PostgreSQL
    authentication using Managed Identity.

.PARAMETER EnvironmentName
    Name of the environment (e.g., dev, staging, prod). Used for resource naming.

.PARAMETER Location
    Azure region for deployment. Default: swedencentral.

.PARAMETER ResourceGroupName
    Name of the resource group to create/use.

.PARAMETER PostgresAdminPassword
    Password for the PostgreSQL administrator account.

.EXAMPLE
    .\deploy.ps1 -EnvironmentName "dev" -ResourceGroupName "rg-photoalbum-dev" -PostgresAdminPassword "YourSecurePassword123!"
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$EnvironmentName,

    [Parameter(Mandatory = $false)]
    [string]$Location = "swedencentral",

    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory = $true)]
    [securestring]$PostgresAdminPassword
)

$ErrorActionPreference = "Stop"

Write-Host "================================================" -ForegroundColor Cyan
Write-Host " Photo Album - Azure Infrastructure Deployment" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Create Resource Group
Write-Host "[1/4] Creating resource group '$ResourceGroupName' in '$Location'..." -ForegroundColor Yellow
az group create --name $ResourceGroupName --location $Location --output none
if ($LASTEXITCODE -ne 0) { throw "Failed to create resource group." }
Write-Host "  Resource group created successfully." -ForegroundColor Green

# Step 2: Deploy Bicep template
Write-Host "[2/4] Deploying Bicep infrastructure template..." -ForegroundColor Yellow
$plainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($PostgresAdminPassword)
)

$deploymentOutput = az deployment group create `
    --resource-group $ResourceGroupName `
    --template-file "$PSScriptRoot\main.bicep" `
    --parameters environmentName=$EnvironmentName `
                 location=$Location `
                 postgresAdminPassword=$plainPassword `
    --query "properties.outputs" `
    --output json

if ($LASTEXITCODE -ne 0) { throw "Bicep deployment failed." }
Write-Host "  Infrastructure deployed successfully." -ForegroundColor Green

# Parse deployment outputs
$outputs = $deploymentOutput | ConvertFrom-Json
$containerAppName = $outputs.containerAppName.value
$containerRegistryName = $outputs.containerRegistryName.value
$containerRegistryLoginServer = $outputs.containerRegistryLoginServer.value
$postgresServerName = $outputs.postgresServerName.value
$postgresDatabaseName = $outputs.postgresDatabaseName.value
$managedIdentityClientId = $outputs.managedIdentityClientId.value
$managedIdentityName = $outputs.managedIdentityName.value
$keyVaultName = $outputs.keyVaultName.value

Write-Host ""
Write-Host "  Deployment Outputs:" -ForegroundColor Cyan
Write-Host "    Container App:     $containerAppName"
Write-Host "    Container Registry: $containerRegistryLoginServer"
Write-Host "    PostgreSQL Server:  $postgresServerName"
Write-Host "    Database:           $postgresDatabaseName"
Write-Host "    Managed Identity:   $managedIdentityName"
Write-Host "    Key Vault:          $keyVaultName"
Write-Host ""

# Step 3: Install Service Connector extension
Write-Host "[3/4] Setting up Service Connector for passwordless PostgreSQL..." -ForegroundColor Yellow
az extension add --name serviceconnector-passwordless --upgrade 2>$null

$subscriptionId = (az account show --query id -o tsv)

# Create Service Connector for passwordless PostgreSQL authentication
az containerapp connection create postgres-flexible `
    --connection photoalbum-db-connection `
    --source-id "/subscriptions/$subscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.App/containerApps/$containerAppName" `
    --target-id "/subscriptions/$subscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.DBforPostgreSQL/flexibleServers/$postgresServerName/databases/$postgresDatabaseName" `
    --user-identity client-id=$managedIdentityClientId subs-id=$subscriptionId `
    --client-type springBoot `
    -c photoalbum `
    -y

if ($LASTEXITCODE -ne 0) { throw "Service Connector creation failed." }
Write-Host "  Service Connector created successfully." -ForegroundColor Green

# Step 4: Summary
Write-Host ""
Write-Host "[4/4] Deployment Complete!" -ForegroundColor Yellow
Write-Host "================================================" -ForegroundColor Green
Write-Host " Infrastructure provisioned successfully!" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Resources created:" -ForegroundColor Cyan
Write-Host "  - Container App:             $containerAppName"
Write-Host "  - Container Registry:        $containerRegistryLoginServer"
Write-Host "  - PostgreSQL Flexible Server: $postgresServerName"
Write-Host "  - Database:                   $postgresDatabaseName"
Write-Host "  - Key Vault:                  $keyVaultName"
Write-Host "  - Managed Identity:           $managedIdentityName"
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Build and push your container image:"
Write-Host "     az acr build --registry $containerRegistryName --image photoalbum:latest ."
Write-Host "  2. Update the container app with your image:"
Write-Host "     az containerapp update --name $containerAppName --resource-group $ResourceGroupName --image $containerRegistryLoginServer/photoalbum:latest"
Write-Host ""
