@description('Location for all resources')
param location string = resourceGroup().location

@description('Application name used to generate resource names')
param appName string = 'photoalbum'

@description('Environment tag (e.g. dev, staging, prod)')
param environmentName string = 'dev'

@description('Azure SQL administrator login name')
param sqlAdminLogin string = 'sqladmin'

@description('Azure SQL administrator password')
@secure()
param sqlAdminPassword string

@description('Container image tag to deploy')
param imageTag string = 'latest'

// ── Resource name variables ──────────────────────────────────────────────────
var acrName = '${appName}acr${uniqueString(resourceGroup().id)}'
var logAnalyticsName = '${appName}-logs-${environmentName}'
var managedIdentityName = '${appName}-mi-${environmentName}'
var containerAppsEnvName = '${appName}-env-${environmentName}'
var containerAppName = '${appName}-${environmentName}'
var sqlServerName = '${appName}-sqlserver-${environmentName}-${uniqueString(resourceGroup().id)}'
var sqlDatabaseName = '${appName}-db'

// ── Modules ──────────────────────────────────────────────────────────────────

module logAnalytics 'modules/logAnalytics.bicep' = {
  name: 'logAnalyticsDeploy'
  params: {
    name: logAnalyticsName
    location: location
    tags: {
      environment: environmentName
      application: appName
    }
  }
}

module managedIdentity 'modules/managedIdentity.bicep' = {
  name: 'managedIdentityDeploy'
  params: {
    name: managedIdentityName
    location: location
    tags: {
      environment: environmentName
      application: appName
    }
  }
}

module containerRegistry 'modules/containerRegistry.bicep' = {
  name: 'containerRegistryDeploy'
  params: {
    name: acrName
    location: location
    tags: {
      environment: environmentName
      application: appName
    }
  }
}

module sqlServer 'modules/sqlServer.bicep' = {
  name: 'sqlServerDeploy'
  params: {
    serverName: sqlServerName
    databaseName: sqlDatabaseName
    location: location
    administratorLogin: sqlAdminLogin
    administratorLoginPassword: sqlAdminPassword
    managedIdentityPrincipalId: managedIdentity.outputs.principalId
    tags: {
      environment: environmentName
      application: appName
    }
  }
}

module containerAppsEnv 'modules/containerAppsEnv.bicep' = {
  name: 'containerAppsEnvDeploy'
  params: {
    name: containerAppsEnvName
    location: location
    logAnalyticsWorkspaceId: logAnalytics.outputs.workspaceId
    tags: {
      environment: environmentName
      application: appName
    }
  }
}

module containerApp 'modules/containerApp.bicep' = {
  name: 'containerAppDeploy'
  params: {
    name: containerAppName
    location: location
    containerAppsEnvId: containerAppsEnv.outputs.environmentId
    acrLoginServer: containerRegistry.outputs.loginServer
    acrName: containerRegistry.outputs.name
    imageTag: imageTag
    managedIdentityId: managedIdentity.outputs.id
    managedIdentityClientId: managedIdentity.outputs.clientId
    managedIdentityPrincipalId: managedIdentity.outputs.principalId
    sqlServerFqdn: sqlServer.outputs.fullyQualifiedDomainName
    sqlDatabaseName: sqlDatabaseName
    tags: {
      environment: environmentName
      application: appName
    }
  }
}

// ── Outputs ──────────────────────────────────────────────────────────────────
output containerAppFqdn string = containerApp.outputs.fqdn
output acrLoginServer string = containerRegistry.outputs.loginServer
output acrName string = containerRegistry.outputs.name
output containerAppName string = containerApp.outputs.name
output sqlServerFqdn string = sqlServer.outputs.fullyQualifiedDomainName
output managedIdentityClientId string = managedIdentity.outputs.clientId
