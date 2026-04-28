@description('Container Apps Environment name')
param name string

@description('Location')
param location string

@description('Log Analytics workspace resource ID')
param logAnalyticsWorkspaceId string

@description('Tags')
param tags object = {}

var workspaceName = last(split(logAnalyticsWorkspaceId, '/'))

resource existingWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: workspaceName
}

resource containerAppsEnv 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: existingWorkspace.properties.customerId
        sharedKey: existingWorkspace.listKeys().primarySharedKey
      }
    }
    zoneRedundant: false
  }
}

output environmentId string = containerAppsEnv.id
output defaultDomain string = containerAppsEnv.properties.defaultDomain
