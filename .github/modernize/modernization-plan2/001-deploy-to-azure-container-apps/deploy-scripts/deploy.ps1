# deploy.ps1 – Deploy Photo Album to Azure Container Apps (Windows)
# Usage: .\deploy.ps1 [-ResourceGroup <name>] [-Location <region>] [-SqlAdminPassword <pwd>] [-ImageTag <tag>]
param(
    [string]$ResourceGroup   = "rg-photo-album-dev",
    [string]$Location        = "eastus",
    [Parameter(Mandatory=$true)]
    [string]$SqlAdminPassword,
    [string]$ImageTag        = "latest",
    [string]$AppName         = "photoalbum",
    [string]$EnvName         = "dev"
)

$ErrorActionPreference = "Stop"
$DeploymentName = "photo-album-deploy-$(Get-Date -Format 'yyyyMMddHHmmss')"
$ScriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$BicepDir   = Split-Path -Parent $ScriptDir

Write-Host "=== Photo Album – Azure Container Apps Deployment ===" -ForegroundColor Cyan
Write-Host "Resource Group : $ResourceGroup"
Write-Host "Location       : $Location"
Write-Host "Image Tag      : $ImageTag"
Write-Host ""

# ── Step 1 – Verify login ─────────────────────────────────────────────────────
Write-Host "[1/7] Verifying Azure CLI login..." -ForegroundColor Yellow
az account show --output none
$SubscriptionId = az account show --query id -o tsv
Write-Host "      Subscription: $SubscriptionId"

# ── Step 2 – Create resource group ───────────────────────────────────────────
Write-Host "[2/7] Creating resource group '$ResourceGroup'..." -ForegroundColor Yellow
az group create --name $ResourceGroup --location $Location --output none

# ── Step 3 – Deploy Bicep ─────────────────────────────────────────────────────
Write-Host "[3/7] Deploying Bicep infrastructure..." -ForegroundColor Yellow
$DeployOutput = az deployment group create `
  --name $DeploymentName `
  --resource-group $ResourceGroup `
  --template-file "$BicepDir\main.bicep" `
  --parameters appName=$AppName `
               environmentName=$EnvName `
               location=$Location `
               sqlAdminLogin="sqladmin" `
               sqlAdminPassword=$SqlAdminPassword `
               imageTag=$ImageTag `
  --output json | ConvertFrom-Json

$AcrName         = $DeployOutput.properties.outputs.acrName.value
$AcrLoginServer  = $DeployOutput.properties.outputs.acrLoginServer.value
$ContainerAppName = $DeployOutput.properties.outputs.containerAppName.value

Write-Host "      ACR            : $AcrLoginServer"
Write-Host "      Container App  : $ContainerAppName"

# ── Step 4 – Build and push image ─────────────────────────────────────────────
Write-Host "[4/7] Building and pushing Docker image to ACR..." -ForegroundColor Yellow
# Locate repo root by searching upward for Dockerfile
$RepoRoot = $ScriptDir
while ($RepoRoot -ne [System.IO.Path]::GetPathRoot($RepoRoot) -and -not (Test-Path "$RepoRoot\Dockerfile")) {
    $RepoRoot = Split-Path -Parent $RepoRoot
}
if (-not (Test-Path "$RepoRoot\Dockerfile")) {
    Write-Error "Could not find Dockerfile from $ScriptDir upward."
    exit 1
}
az acr build `
  --registry $AcrName `
  --resource-group $ResourceGroup `
  --image "photo-album:$ImageTag" `
  --file "$RepoRoot\Dockerfile" `
  $RepoRoot

# ── Step 5 – Update container app ────────────────────────────────────────────
Write-Host "[5/7] Updating Container App with new image..." -ForegroundColor Yellow
az containerapp update `
  --name $ContainerAppName `
  --resource-group $ResourceGroup `
  --image "$AcrLoginServer/photo-album:$ImageTag" `
  --output none

# ── Step 6 – Wait for Running ────────────────────────────────────────────────
Write-Host "[6/7] Waiting for Container App to reach Running state..." -ForegroundColor Yellow
for ($i = 1; $i -le 20; $i++) {
    $Status = az containerapp show `
        --name $ContainerAppName `
        --resource-group $ResourceGroup `
        --query "properties.runningStatus" -o tsv 2>$null
    Write-Host "      Attempt $i/20 – status: $Status"
    if ($Status -eq "Running") { break }
    Start-Sleep -Seconds 15
}

# ── Step 7 – Print summary ────────────────────────────────────────────────────
$AppFqdn = az containerapp show `
    --name $ContainerAppName `
    --resource-group $ResourceGroup `
    --query "properties.configuration.ingress.fqdn" -o tsv 2>$null

Write-Host ""
Write-Host "=== Deployment Complete ===" -ForegroundColor Green
Write-Host "  Application URL : https://$AppFqdn"
Write-Host "  Resource Group  : $ResourceGroup"
Write-Host "  Container App   : $ContainerAppName"
Write-Host "  ACR             : $AcrLoginServer"
Write-Host ""
Write-Host "View logs:"
Write-Host "  az containerapp logs show --name $ContainerAppName --resource-group $ResourceGroup --follow"
