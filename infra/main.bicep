@description('Location for all resources')
param location string = resourceGroup().location

@description('Application name used as base for all resource names')
param appName string = 'photoalbum'

@description('Environment tag (dev, staging, prod)')
param environment string = 'prod'

@description('Container image to deploy (e.g. <acr-login-server>/photoalbum:latest). Defaults to a placeholder; override this after ACR is provisioned.')
param containerImage string = 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'

@description('PostgreSQL admin username')
param postgresAdminUser string = 'photoalbumadmin'

@secure()
@description('PostgreSQL admin password')
param postgresAdminPassword string

@description('PostgreSQL database name')
param postgresDatabaseName string = 'photoalbum'

@description('PostgreSQL app user (used by the application)')
param postgresAppUser string = 'photoalbum'

@secure()
@description('PostgreSQL app password')
param postgresAppPassword string

// Unique suffix for globally unique names
var uniqueSuffix = uniqueString(resourceGroup().id)
var acrName = '${appName}acr${uniqueSuffix}'
var logAnalyticsName = '${appName}-logs-${uniqueSuffix}'
var containerAppsEnvName = '${appName}-env-${environment}'
var containerAppName = '${appName}-app-${environment}'
var postgresServerName = '${appName}-db-${uniqueSuffix}'

// Azure Container Registry
resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: acrName
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: true
  }
  tags: {
    environment: environment
    application: appName
  }
}

// Log Analytics Workspace
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: logAnalyticsName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
  tags: {
    environment: environment
    application: appName
  }
}

// Container Apps Environment
resource containerAppsEnv 'Microsoft.App/managedEnvironments@2023-05-01' = {
  name: containerAppsEnvName
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalytics.properties.customerId
        sharedKey: logAnalytics.listKeys().primarySharedKey
      }
    }
  }
  tags: {
    environment: environment
    application: appName
  }
}

// Azure Database for PostgreSQL Flexible Server
resource postgresServer 'Microsoft.DBforPostgreSQL/flexibleServers@2023-06-01-preview' = {
  name: postgresServerName
  location: location
  sku: {
    name: 'Standard_B1ms'
    tier: 'Burstable'
  }
  properties: {
    administratorLogin: postgresAdminUser
    administratorLoginPassword: postgresAdminPassword
    version: '16'
    storage: {
      storageSizeGB: 32
    }
    backup: {
      backupRetentionDays: 7
      geoRedundantBackup: 'Disabled'
    }
    network: {
      // Public network access is enabled to allow Azure Container Apps to connect.
      // Azure services (0.0.0.0 → 0.0.0.0 firewall rule) are allowed; all other
      // public IPs are blocked by the firewall. For production hardening, consider
      // enabling VNet integration and switching publicNetworkAccess to 'Disabled'.
      publicNetworkAccess: 'Enabled'
    }
    highAvailability: {
      mode: 'Disabled'
    }
  }
  tags: {
    environment: environment
    application: appName
  }
}

// PostgreSQL database
resource postgresDatabase 'Microsoft.DBforPostgreSQL/flexibleServers/databases@2023-06-01-preview' = {
  parent: postgresServer
  name: postgresDatabaseName
  properties: {
    charset: 'UTF8'
    collation: 'en_US.UTF8'
  }
}

// PostgreSQL firewall rule - allow Azure services
resource postgresFirewallAllowAzure 'Microsoft.DBforPostgreSQL/flexibleServers/firewallRules@2023-06-01-preview' = {
  parent: postgresServer
  name: 'AllowAllAzureServicesAndResourcesWithinAzureIps'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

// Container App
resource containerApp 'Microsoft.App/containerApps@2023-05-01' = {
  name: containerAppName
  location: location
  properties: {
    managedEnvironmentId: containerAppsEnv.id
    configuration: {
      activeRevisionsMode: 'Single'
      ingress: {
        external: true
        targetPort: 8080
        allowInsecure: false
        traffic: [
          {
            latestRevision: true
            weight: 100
          }
        ]
      }
      registries: [
        {
          server: acr.properties.loginServer
          username: acr.name
          passwordSecretRef: 'acr-password'
        }
      ]
      secrets: [
        {
          name: 'acr-password'
          value: acr.listCredentials().passwords[0].value
        }
        {
          name: 'postgres-connection-string'
          value: 'jdbc:postgresql://${postgresServer.properties.fullyQualifiedDomainName}:5432/${postgresDatabaseName}?sslmode=require'
        }
        {
          name: 'postgres-username'
          value: postgresAppUser
        }
        {
          name: 'postgres-password'
          value: postgresAppPassword
        }
      ]
    }
    template: {
      containers: [
        {
          name: appName
          image: containerImage
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
              name: 'AZURE_POSTGRESQL_CONNECTION_STRING'
              secretRef: 'postgres-connection-string'
            }
            {
              name: 'AZURE_POSTGRESQL_USERNAME'
              secretRef: 'postgres-username'
            }
            {
              name: 'AZURE_POSTGRESQL_PASSWORD'
              secretRef: 'postgres-password'
            }
            {
              name: 'JAVA_OPTS'
              value: '-Xmx512m -Xms256m'
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
                concurrentRequests: '50'
              }
            }
          }
        ]
      }
    }
  }
  tags: {
    environment: environment
    application: appName
  }
}

// Outputs
output containerAppUrl string = 'https://${containerApp.properties.configuration.ingress.fqdn}'
output acrLoginServer string = acr.properties.loginServer
output acrName string = acr.name
output postgresServerName string = postgresServer.name
output postgresServerFqdn string = postgresServer.properties.fullyQualifiedDomainName
output containerAppName string = containerApp.name
output resourceGroupName string = resourceGroup().name
