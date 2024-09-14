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
var storageAccountBlobContainerName = 'datalake'
var storageEndpointName = 'hallinc-storage-endpoint'
var storageLinkName = 'hallinc-storage-link'
var databaseEndpointName = 'hallinc-database-endpoint'
var databaseLinkName = 'hallinc-database-link'

var sqlServerName = 'hallinc-${resourceNameSuffix}'
var sqlDatabaseName = 'WorldWideImporters'

// Define the connection string to access Azure SQL.

// set evironment configuration for resources 
var environmentConfiguration = {
  Test: {
    storageAccountType: 'Standard_LRS'
    properties: {
      isHnsEnabled: true
      allowBlobPublicAccess: true
      networkAcls: {
        bypass: 'AzureServices, Logging, Metrics'
        defaultAction: 'Deny'
      }
    }
    blobContainers: {
      properties: {
        publicAccess: 'None'
      }
    }
    sqlDatabase: {
      properties: {
        collation: 'SQL_Latin1_General_CP1_CI_AS'
        autoPauseDelay: '30'
        freeLimitExhaustionBehavior: 'Pause'
        useFreeLimit: true
      }
      sku: {
        name: 'Basic'
        tier: 'basic'
      }
    }
  }
  Production: {
    storageAccountType: 'Premium_LRS'
    properties: {
      isHnsEnabled: null
      networkAcls: {
        bypass: 'AzureServices, Logging, Metrics'
        defaultAction: 'Deny'
      }
    }

    blobContainers: {
      properties: {
        publicAccess: 'None'
      }
    }
    sqlDatabase: {
      properties: {
        collation: 'SQL_Latin1_General_CP1_CI_AS'
      }
      sku: {
        name: 'Standard'
        tier: 'Standard'
      }
    }
  }
}

module databricks_nsg 'modules/databricks_nsg.bicep' = {
  name: 'databricks_nsg'
  params: {
    location: location
    nsgName: 'databricks-nsg'
  }
}

// create a vnet resource with public subnet, private subnets and private link subnets
module databricks_vnet 'modules/databricks_vnet.bicep' = {
  name: 'databricks_vnet'
  params: {
    location: location
    nsgId: databricks_nsg.outputs.nsgId
  }
}

// create a storage account resource with hiearchical namespace enabled
module storage 'modules/storage.bicep' = {
  name: 'storage'
  params: {
    storageAccountName: storageAccountName
    storageAccountBlobContainerName: storageAccountBlobContainerName
    location: location
    environmentType: environmentType
    environmentConfiguration: environmentConfiguration
    storageEndpointName: storageEndpointName
    storageLinkName: storageLinkName
    vnetId: databricks_vnet.outputs.vnetId
    privateSubnetId: databricks_vnet.outputs.privateSubnetId
  }
}

module sql_database 'modules/database.bicep' = {
  name: sqlDatabaseName
  params: {
    location: location
    environmentType: environmentType
    environmentConfiguration: environmentConfiguration
    sqlServerName: sqlServerName
    sqlDatabaseName: sqlDatabaseName
    sqlServerAdministratorLogin: sqlServerAdministratorLogin
    sqlServerAdministratorLoginPassword: sqlServerAdministratorLoginPassword
    databaseEndpointName: databaseEndpointName
    databaseLinkName: databaseLinkName
    vnetId: databricks_vnet.outputs.vnetId
    privateSubnetId: databricks_vnet.outputs.privateSubnetId
  }
}
