targetScope = 'resourceGroup'

// =============================================
// Parameters
// =============================================

@description('Name of the environment (e.g., dev, staging, prod)')
param environmentName string

@description('Primary location for all resources')
param location string = 'swedencentral'

@description('PostgreSQL administrator login name')
param postgresAdminLogin string = 'pgadmin'

@description('PostgreSQL administrator password')
@secure()
param postgresAdminPassword string

@description('Name of the PostgreSQL database')
param postgresDatabaseName string = 'photoalbum'

// =============================================
// Variables
// =============================================

var resourceToken = uniqueString(subscription().id, resourceGroup().id, location, environmentName)
var tags = {
  environment: environmentName
  project: 'photoalbum'
}

// =============================================
// Modules
// =============================================

// 1. Log Analytics Workspace
module logAnalytics 'modules/log-analytics.bicep' = {
  name: 'logAnalytics'
  params: {
    name: 'azlog${resourceToken}'
    location: location
    tags: tags
  }
}

// 2. User-Assigned Managed Identity
module managedIdentity 'modules/managed-identity.bicep' = {
  name: 'managedIdentity'
  params: {
    name: 'azid${resourceToken}'
    location: location
    tags: tags
  }
}

// 3. Azure Container Registry
module containerRegistry 'modules/container-registry.bicep' = {
  name: 'containerRegistry'
  params: {
    name: 'azcr${resourceToken}'
    location: location
    tags: tags
    sku: 'Basic'
  }
}

// 4. AcrPull Role Assignment - MUST be defined BEFORE any container apps
resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, 'acrpull', resourceToken)
  properties: {
    principalId: managedIdentity.outputs.principalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')
    principalType: 'ServicePrincipal'
  }
  dependsOn: [
    containerRegistry
  ]
}

// 5. Key Vault
module keyVault 'modules/key-vault.bicep' = {
  name: 'keyVault'
  params: {
    name: 'azkv${resourceToken}'
    location: location
    tags: tags
    managedIdentityPrincipalId: managedIdentity.outputs.principalId
    postgresAdminLogin: postgresAdminLogin
    postgresAdminPassword: postgresAdminPassword
  }
}

// 6. Azure Database for PostgreSQL Flexible Server
module postgresql 'modules/postgresql.bicep' = {
  name: 'postgresql'
  params: {
    name: 'azpg${resourceToken}'
    location: location
    tags: tags
    administratorLogin: postgresAdminLogin
    administratorPassword: postgresAdminPassword
    databaseName: postgresDatabaseName
    version: '17'
    skuName: 'Standard_B1ms'
    skuTier: 'Burstable'
    storageSizeGB: 32
  }
}

// 7. Container Apps Environment
module containerAppEnvironment 'modules/container-app-environment.bicep' = {
  name: 'containerAppEnvironment'
  params: {
    name: 'azce${resourceToken}'
    location: location
    tags: tags
    logAnalyticsCustomerId: logAnalytics.outputs.customerId
    logAnalyticsPrimarySharedKey: logAnalytics.outputs.primarySharedKey
  }
}

// 8. Container App (depends on AcrPull role assignment)
module containerApp 'modules/container-app.bicep' = {
  name: 'containerApp'
  params: {
    name: 'azca${resourceToken}'
    location: location
    tags: tags
    containerAppEnvironmentId: containerAppEnvironment.outputs.id
    managedIdentityId: managedIdentity.outputs.id
    containerRegistryLoginServer: containerRegistry.outputs.loginServer
    containerImage: 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'
    targetPort: 8080
    envVars: [
      {
        name: 'SPRING_PROFILES_ACTIVE'
        value: 'azure'
      }
    ]
  }
  dependsOn: [
    acrPullRoleAssignment
    keyVault
  ]
}

// =============================================
// Outputs
// =============================================

output containerAppFqdn string = containerApp.outputs.fqdn
output containerAppName string = containerApp.outputs.name
output containerRegistryLoginServer string = containerRegistry.outputs.loginServer
output containerRegistryName string = containerRegistry.outputs.name
output postgresServerFqdn string = postgresql.outputs.fqdn
output postgresServerName string = postgresql.outputs.name
output postgresDatabaseName string = postgresql.outputs.databaseName
output managedIdentityClientId string = managedIdentity.outputs.clientId
output managedIdentityName string = managedIdentity.outputs.name
output managedIdentityId string = managedIdentity.outputs.id
output keyVaultName string = keyVault.outputs.name
output keyVaultUri string = keyVault.outputs.uri
output logAnalyticsName string = logAnalytics.outputs.name
output containerAppEnvironmentName string = containerAppEnvironment.outputs.name
output resourceToken string = resourceToken
