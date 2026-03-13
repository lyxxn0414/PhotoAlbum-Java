// PhotoAlbum-Java – Resource-group-scoped resources
// All Azure resources are defined here and called from main.bicep.
//
// Naming convention (rule): az{prefix}{resourceToken}
//   resourceToken = uniqueString(subscription().id, resourceGroup().id, location, environmentName)

targetScope = 'resourceGroup'

// ─── Parameters ────────────────────────────────────────────────────────────────
@minLength(1)
@maxLength(64)
param environmentName string

@minLength(1)
param location string = resourceGroup().location

@description('PostgreSQL administrator login name.')
param postgresAdminUsername string

@secure()
@description('PostgreSQL administrator password.')
param postgresAdminPassword string

// ─── Resource token ─────────────────────────────────────────────────────────────
var resourceToken = uniqueString(subscription().id, resourceGroup().id, location, environmentName)

// ─────────────────────────────────────────────────────────────────────────────────
// 1. User-Assigned Managed Identity (UAMI)
// ─────────────────────────────────────────────────────────────────────────────────
resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'azid${resourceToken}'
  location: location
}

// ─────────────────────────────────────────────────────────────────────────────────
// 2. Log Analytics Workspace
// ─────────────────────────────────────────────────────────────────────────────────
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: 'azlaw${resourceToken}'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

// ─────────────────────────────────────────────────────────────────────────────────
// 3. Application Insights  (connected to Log Analytics)
// ─────────────────────────────────────────────────────────────────────────────────
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: 'azai${resourceToken}'
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalytics.id
  }
}

// ─────────────────────────────────────────────────────────────────────────────────
// 4. Key Vault  (RBAC mode, public access enabled)
// ─────────────────────────────────────────────────────────────────────────────────
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: 'azkv${resourceToken}'
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enableRbacAuthorization: true       // rule: use RBAC auth
    publicNetworkAccess: 'Enabled'      // rule: allow public access from all networks
    enabledForDeployment: false
    enabledForTemplateDeployment: false
    enabledForDiskEncryption: false
  }
}

// 4a. Key Vault Secrets Officer role for UAMI
//     role id: b86a8fe4-44ce-4948-aee5-eccb2c155cd7
var kvSecretsOfficerRoleId = 'b86a8fe4-44ce-4948-aee5-eccb2c155cd7'

resource kvSecretsOfficerAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVault.id, managedIdentity.id, kvSecretsOfficerRoleId)
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', kvSecretsOfficerRoleId)
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// 4b. Store PostgreSQL credentials in Key Vault
//     Explicit dependsOn so the role exists before secret creation
resource kvSecretPgUsername 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'postgres-admin-username'
  dependsOn: [kvSecretsOfficerAssignment]
  properties: {
    value: postgresAdminUsername
  }
}

resource kvSecretPgPassword 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'postgres-admin-password'
  dependsOn: [kvSecretsOfficerAssignment]
  properties: {
    value: postgresAdminPassword
  }
}

// ─────────────────────────────────────────────────────────────────────────────────
// 5. Azure Container Registry  (admin disabled; UAMI pulls via AcrPull)
// ─────────────────────────────────────────────────────────────────────────────────
resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: 'azacr${resourceToken}'
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: false
  }
}

// 5a. AcrPull role for UAMI  – MUST be defined BEFORE any Container App
//     role id: 7f951dda-4ed3-4680-a7ca-43fe172d538d
var acrPullRoleId = '7f951dda-4ed3-4680-a7ca-43fe172d538d'

resource acrPullAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acr.id, managedIdentity.id, acrPullRoleId)
  scope: acr
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', acrPullRoleId)
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// ─────────────────────────────────────────────────────────────────────────────────
// 6. Azure Database for PostgreSQL Flexible Server
//    SKU: Standard_D2ds_v5 (GeneralPurpose, 2 vCores) – rule mandated
//    Version: 17 – rule mandated
//    DB name: photoalbum (never "postgres" – rule)
// ─────────────────────────────────────────────────────────────────────────────────
resource postgresServer 'Microsoft.DBforPostgreSQL/flexibleServers@2023-12-01-preview' = {
  name: 'azpg${resourceToken}'
  location: location
  sku: {
    name: 'Standard_D2ds_v5'
    tier: 'GeneralPurpose'
  }
  properties: {
    administratorLogin: postgresAdminUsername
    administratorLoginPassword: postgresAdminPassword
    version: '17'
    storage: {
      storageSizeGB: 32
    }
    backup: {
      backupRetentionDays: 7
      geoRedundantBackup: 'Disabled'
    }
    highAvailability: {
      mode: 'Disabled'
    }
    authConfig: {
      activeDirectoryAuth: 'Enabled'   // needed for Managed Identity
      passwordAuth: 'Enabled'
      tenantId: subscription().tenantId
    }
  }
}

// 6a. Firewall rule: allow traffic from Azure services (0.0.0.0)
resource postgresFirewall 'Microsoft.DBforPostgreSQL/flexibleServers/firewallRules@2023-12-01-preview' = {
  parent: postgresServer
  name: 'AllowAzureServices'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

// 6b. Application database
resource postgresDb 'Microsoft.DBforPostgreSQL/flexibleServers/databases@2023-12-01-preview' = {
  parent: postgresServer
  name: 'photoalbum'
  properties: {
    charset: 'UTF8'
    collation: 'en_US.utf8'
  }
}

// ─────────────────────────────────────────────────────────────────────────────────
// 7. Container Apps Environment  (connected to Log Analytics)
// ─────────────────────────────────────────────────────────────────────────────────
resource containerAppEnvironment 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: 'azcae${resourceToken}'
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
}

// ─────────────────────────────────────────────────────────────────────────────────
// 8. Container App
//    - tag azd-service-name must match service name in azure.yaml
//    - base image: mcr.microsoft.com/azuredocs/containerapps-helloworld:latest (rule)
//    - uses UAMI identity (not system)
//    - SPRING_DATASOURCE_* env vars are set by Service Connector (post-provision hook)
// ─────────────────────────────────────────────────────────────────────────────────
resource containerApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: 'azca${resourceToken}'
  location: location
  tags: {
    // Rule: tag 'azd-service-name' must match the service name in azure.yaml
    'azd-service-name': 'photoalbum-java-app'
  }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  // Rule: AcrPull role assignment and KV secrets must exist before Container App
  dependsOn: [
    acrPullAssignment
    kvSecretsOfficerAssignment
    kvSecretPgUsername
    kvSecretPgPassword
  ]
  properties: {
    managedEnvironmentId: containerAppEnvironment.id
    configuration: {
      ingress: {
        external: true
        targetPort: 8080
        transport: 'auto'
        // Rule: enable CORS
        corsPolicy: {
          allowedOrigins: ['*']
          allowedMethods: ['*']
          allowedHeaders: ['*']
          allowCredentials: false
        }
      }
      // Rule: set registry connection using UAMI identity (not admin credentials)
      registries: [
        {
          server: acr.properties.loginServer
          identity: managedIdentity.id
        }
      ]
    }
    template: {
      containers: [
        {
          name: 'photoalbum-java-app'
          // Rule: base image must be containerapps-helloworld; azd deploy replaces it
          image: 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'
          resources: {
            cpu: json('0.5')
            memory: '1Gi'
          }
          env: [
            {
              // Activate Azure Spring profile
              name: 'SPRING_PROFILES_ACTIVE'
              value: 'azure'
            }
            {
              // PostgreSQL server hostname for JDBC connection
              name: 'POSTGRES_HOST'
              value: '${postgresServer.name}.postgres.database.azure.com'
            }
            {
              // PostgreSQL database name
              name: 'POSTGRES_DATABASE'
              value: postgresDb.name
            }
            {
              // Azure AD user created by Service Connector for managed identity auth
              name: 'POSTGRES_USERNAME'
              value: 'aad_photoalbum_postgresql'
            }
            {
              // Managed Identity client ID for Azure AD auth
              name: 'AZURE_CLIENT_ID'
              value: managedIdentity.properties.clientId
            }
          ]
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 10
      }
    }
  }
}

// ─── Outputs ────────────────────────────────────────────────────────────────────
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = acr.properties.loginServer
output AZURE_CONTAINER_REGISTRY_NAME string = acr.name
output AZURE_CONTAINER_APP_NAME string = containerApp.name
output AZURE_CONTAINER_APP_ENVIRONMENT_NAME string = containerAppEnvironment.name
output POSTGRES_SERVER_NAME string = postgresServer.name
output POSTGRES_DATABASE_NAME string = postgresDb.name
output MANAGED_IDENTITY_CLIENT_ID string = managedIdentity.properties.clientId
output CONTAINER_APP_RESOURCE_ID string = containerApp.id
