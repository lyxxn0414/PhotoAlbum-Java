@description('Container App name')
param name string

@description('Location')
param location string

@description('Container Apps Environment resource ID')
param containerAppsEnvId string

@description('Azure Container Registry login server')
param acrLoginServer string

@description('Azure Container Registry name')
param acrName string

@description('Container image tag')
param imageTag string = 'latest'

@description('User-assigned managed identity resource ID')
param managedIdentityId string

@description('User-assigned managed identity client ID')
param managedIdentityClientId string

@description('Azure SQL Server FQDN')
param sqlServerFqdn string

@description('Azure SQL Database name')
param sqlDatabaseName string

@description('Tags')
param tags object = {}

var imageName = '${acrLoginServer}/photo-album:${imageTag}'

resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = {
  name: acrName
}

resource containerApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: name
  location: location
  tags: tags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentityId}': {}
    }
  }
  properties: {
    environmentId: containerAppsEnvId
    configuration: {
      activeRevisionsMode: 'Single'
      ingress: {
        external: true
        targetPort: 8080
        transport: 'http'
        allowInsecure: false
      }
      registries: [
        {
          server: acrLoginServer
          identity: managedIdentityId
        }
      ]
    }
    template: {
      containers: [
        {
          name: 'photo-album'
          image: imageName
          resources: {
            cpu: json('0.5')
            memory: '1Gi'
          }
          env: [
            {
              name: 'SPRING_PROFILES_ACTIVE'
              value: 'azure'
            }
            {
              name: 'DATABASE_SERVER_HOST_NAME'
              value: sqlServerFqdn
            }
            {
              name: 'DATABASE_NAME'
              value: sqlDatabaseName
            }
            {
              name: 'AZURE_MANAGED_IDENTITY_CLIENT_ID'
              value: managedIdentityClientId
            }
            {
              name: 'JAVA_OPTS'
              value: '-Xmx512m -Xms256m'
            }
          ]
          probes: [
            {
              type: 'Liveness'
              httpGet: {
                path: '/actuator/health'
                port: 8080
              }
              initialDelaySeconds: 30
              periodSeconds: 30
              failureThreshold: 3
            }
            {
              type: 'Readiness'
              httpGet: {
                path: '/actuator/health'
                port: 8080
              }
              initialDelaySeconds: 15
              periodSeconds: 10
              failureThreshold: 3
            }
          ]
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 3
        rules: [
          {
            name: 'http-scaling'
            http: {
              metadata: {
                concurrentRequests: '10'
              }
            }
          }
        ]
      }
    }
  }
}

// Grant AcrPull role to managed identity on ACR
resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acr.id, managedIdentityId, '7f951dda-4ed3-4680-a7ca-43fe172d538d')
  scope: acr
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')
    principalId: reference(managedIdentityId, '2023-01-31', 'Full').properties.principalId
    principalType: 'ServicePrincipal'
  }
}

output fqdn string = containerApp.properties.configuration.ingress.fqdn
output name string = containerApp.name
output id string = containerApp.id
