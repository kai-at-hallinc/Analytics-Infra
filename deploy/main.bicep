@description('The Azure region into which the resources should be deployed.')
param location string = resourceGroup().location

@description('The type of environment (dev or prod.')
@allowed([
  'Test'
  'Production'
])
param environmentType string

@description('A unique suffix to add to resource names that need to be globally unique.')
@maxLength(13)
param resourceNameSuffix string = uniqueString(resourceGroup().id)

@description('The administrator login username for the SQL server.')
param sqlServerAdministratorLogin string

@secure()
@description('The administrator login password for the SQL server.')
param sqlServerAdministratorLoginPassword string

var storageAccountName = 'hallincst${resourceNameSuffix}'
var environmentConfiguration = {
  Test: {
    storageAccountType: 'Standard_LRS'
    properties: {
      isHnsEnabled: true
    }
    sqlDatabase: {
      sku: {
        name: 'Standard'
        tier: 'Standard'
      }
    }
  }
  Production: {
    storageAccountType: 'Premium_LRS'
    properties: {
      isHnsEnabled: null
    }
    sqlDatabase: {
      sku: {
        name: 'Standard'
        tier: 'Standard'
      }
    }
  }
}

var storageAccountBlobContainerName = 'data'
var sqlServerName = 'hallinc-${resourceNameSuffix}'
var sqlDatabaseName = 'WorldWideImporters'

// Define the connection string to access Azure SQL.
var sqlDatabaseConnectionString = '''
  Server=tcp:${sqlServer.properties.fullyQualifiedDomainName},1433;
  Initial Catalog=${sqlDatabase.name};
  Persist Security Info=False;
  User ID=${sqlServerAdministratorLogin};
  Password=${sqlServerAdministratorLoginPassword};
  MultipleActiveResultSets=False;
  Encrypt=True;
  TrustServerCertificate=False;
  Connection Timeout=30;
'''

// create a storage account resource with hiearchical namespace enabled
resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: environmentConfiguration[environmentType].storageAccountType
  }
  kind: 'StorageV2'
  properties: environmentConfiguration[environmentType].properties

  resource blobService 'blobServices' = {
    name: 'default'

    resource storageAccountBlobContainer 'containers' = {
      name: storageAccountBlobContainerName
      properties: {
        publicAccess: 'Blob'
      }
    }
  }
}

resource sqlServer 'Microsoft.Sql/servers@2022-05-01-preview' = {
  name: sqlServerName
  location: location
  properties: {
    administratorLogin: sqlServerAdministratorLogin
    administratorLoginPassword: sqlServerAdministratorLoginPassword
  }
}

resource sqlServerFirewallRule 'Microsoft.Sql/servers/firewallRules@2022-05-01-preview' = {
  parent: sqlServer
  name: 'AllowAllAzureIps'
  properties: {
    endIpAddress: '0.0.0.0'
    startIpAddress: '0.0.0.0'
  }
}

resource sqlDatabase 'Microsoft.Sql/servers/databases@2022-05-01-preview' = {
  parent: sqlServer
  name: sqlDatabaseName
  location: location
  sku: environmentConfiguration[environmentType].sqlDatabase.sku
}

output storageAccountName string = storageAccount.name
output storageAccountImagesBlobContainerName string = storageAccount::blobService::storageAccountBlobContainer.name
output sqlServerFullyQualifiedDomainName string = sqlServer.properties.fullyQualifiedDomainName
output sqlDatabaseName string = sqlDatabase.name
output sqlDatabaseConnectionString string = sqlDatabaseConnectionString
