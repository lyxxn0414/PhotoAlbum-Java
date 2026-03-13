// PhotoAlbum-Java – Azure Infrastructure (subscription scope)
// Provisions resource group + delegates all resources to resources.bicep

targetScope = 'subscription'

// ─── Parameters ────────────────────────────────────────────────────────────────
@minLength(1)
@maxLength(64)
@description('Name of the AZD environment; used as naming basis for all resources.')
param environmentName string

@minLength(1)
@description('Primary Azure region for all resources.')
param location string = 'eastus'

@description('PostgreSQL administrator login name.')
param postgresAdminUsername string = 'photoalbum'

@secure()
@description('PostgreSQL administrator password.')
param postgresAdminPassword string

// ─── Resource Group ─────────────────────────────────────────────────────────────
var resourceGroupName = 'rg-${environmentName}'

resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: resourceGroupName
  location: location
  // Rule: Resource Group must carry tag 'azd-env-name'
  tags: {
    'azd-env-name': environmentName
  }
}

// ─── Resources module (resource-group scope) ────────────────────────────────────
module resources 'resources.bicep' = {
  name: 'resources'
  scope: rg
  params: {
    environmentName: environmentName
    location: location
    postgresAdminUsername: postgresAdminUsername
    postgresAdminPassword: postgresAdminPassword
  }
}

// ─── Outputs (surfaced as AZD env vars for hooks & CLI) ─────────────────────────
output RESOURCE_GROUP_ID string = rg.id
output AZURE_RESOURCE_GROUP string = rg.name
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = resources.outputs.AZURE_CONTAINER_REGISTRY_ENDPOINT
output AZURE_CONTAINER_REGISTRY_NAME string = resources.outputs.AZURE_CONTAINER_REGISTRY_NAME
output AZURE_CONTAINER_APP_NAME string = resources.outputs.AZURE_CONTAINER_APP_NAME
output AZURE_CONTAINER_APP_ENVIRONMENT_NAME string = resources.outputs.AZURE_CONTAINER_APP_ENVIRONMENT_NAME
output POSTGRES_SERVER_NAME string = resources.outputs.POSTGRES_SERVER_NAME
output POSTGRES_DATABASE_NAME string = resources.outputs.POSTGRES_DATABASE_NAME
output MANAGED_IDENTITY_CLIENT_ID string = resources.outputs.MANAGED_IDENTITY_CLIENT_ID
output CONTAINER_APP_RESOURCE_ID string = resources.outputs.CONTAINER_APP_RESOURCE_ID
