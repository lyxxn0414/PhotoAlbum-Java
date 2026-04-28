@description('Azure SQL Server name')
param serverName string

@description('Azure SQL Database name')
param databaseName string

@description('Location')
param location string

@description('SQL administrator login')
param administratorLogin string

@description('SQL administrator password')
@secure()
param administratorLoginPassword string

@description('Principal ID of the managed identity to grant db_owner')
param managedIdentityPrincipalId string

@description('Tags')
param tags object = {}

resource sqlServer 'Microsoft.Sql/servers@2023-05-01-preview' = {
  name: serverName
  location: location
  tags: tags
  properties: {
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    minimalTlsVersion: '1.2'
    publicNetworkAccess: 'Enabled'
  }
}

// Allow Azure services to connect
resource allowAzureServices 'Microsoft.Sql/servers/firewallRules@2023-05-01-preview' = {
  parent: sqlServer
  name: 'AllowAllAzureIPs'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

resource sqlDatabase 'Microsoft.Sql/servers/databases@2023-05-01-preview' = {
  parent: sqlServer
  name: databaseName
  location: location
  tags: tags
  sku: {
    name: 'Basic'
    tier: 'Basic'
    capacity: 5
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: 2147483648
  }
}

// Azure AD admin for Managed Identity
resource sqlAadAdmin 'Microsoft.Sql/servers/administrators@2023-05-01-preview' = {
  parent: sqlServer
  name: 'ActiveDirectory'
  properties: {
    administratorType: 'ActiveDirectory'
    login: 'aad-admin'
    sid: managedIdentityPrincipalId
    tenantId: subscription().tenantId
  }
}

output fullyQualifiedDomainName string = sqlServer.properties.fullyQualifiedDomainName
output sqlServerId string = sqlServer.id
output sqlDatabaseId string = sqlDatabase.id
