@description('The Azure region into which the resources should be deployed.')
param location string = resourceGroup().location

@description('The type of environment (dev or prod.')
param environmentType string

@description('A unique suffix to add to resource names that need to be globally unique.')
@maxLength(13)
param resourceNameSuffix string = uniqueString(resourceGroup().id)

@description('The administrator login username for the SQL server.')
param sqlServerAdministratorLogin string

@description('The administrator login password for the SQL server.')
@secure()
param sqlServerAdministratorLoginPassword string

@description('if to deploy Azure Databricks workspace with Secure Cluster Connectivity')
param disablePublicIp bool

@description('The name of the Azure Databricks workspace to create.')
param databricksWorkspaceName string = 'hallinc-${resourceNameSuffix}'

@description('The pricing tier of the Azure Databricks workspace.')
param databricksPricingTier string

@description('The environment configuration settings.')
param environmentConfiguration object

@description('role assignments for user managed identity')
param managedIdentityRoleDefinitionIds array

@description('role assignments for databricks connector')
param databricksConnectorRoleDefinitionIds array

@maxLength(24)
param keyVaultName string = 'hallinckv${resourceNameSuffix}'

var storageAccountName = 'hallincst${resourceNameSuffix}'
var storageAccountBlobContainerName = 'datalake'
var databaseEndpointName = 'hallinc-database-endpoint'
var databaseLinkName = 'hallinc-database-link'
var sqlServerName = 'hallinc-${resourceNameSuffix}'
var sqlDatabaseName = 'WorldWideImporters'
var deploy_rg = false

//create a resource group if deploy_rg is true

module resourceGroups 'modules/resourceGroups.bicep' = if (deploy_rg) {
  name: 'ResourceGroupDeployment'
  scope: subscription()
  params: {
    location: location
    environmentType: environmentType
    resourceNameSuffix: resourceNameSuffix
  }
}

//create a network security group resource for databricks communications
module databricks_nsg 'modules/databricks_nsg.bicep' = {
  name: 'databricks_nsg'
  params: {
    location: location
    nsgName: 'databricks-nsg'
  }
}

//create a vnet resource with public subnet, private subnets and private link subnets
module databricks_vnet 'modules/databricks_vnet.bicep' = {
  name: 'databricks_vnet'
  params: {
    location: location
    nsgId: databricks_nsg.outputs.nsgId
  }
}

//create a storage account resource with hiearchical namespace enabled
module storage 'modules/storage.bicep' = {
  name: 'storage'
  params: {
    storageAccountName: storageAccountName
    storageAccountBlobContainerName: storageAccountBlobContainerName
    location: location
    environmentType: environmentType
    environmentConfiguration: environmentConfiguration
    vnetId: databricks_vnet.outputs.vnetId
    privateLinkSubnetId: databricks_vnet.outputs.privateLinkSubnetId
  }
}

//create a sql database resource with private endpoint
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
    privateLinkSubnetId: databricks_vnet.outputs.privateLinkSubnetId
  }
}

//create a databricks workspace with secure cluster connectivity and vnet injection
module databricks_workspace 'modules/databricks-workspace.bicep' = {
  name: 'databricks_workspace'
  params: {
    location: location
    disablePublicIp: disablePublicIp
    workspaceName: databricksWorkspaceName
    pricingTier: databricksPricingTier
    vnetId: databricks_vnet.outputs.vnetId
    publicSubnetName: databricks_vnet.outputs.publicSubnetName
    privateSubnetName: databricks_vnet.outputs.privateSubnetName
    managedIdentityRoleDefinitionIds: managedIdentityRoleDefinitionIds
    databricksConnectorRoleDefinitionIds: databricksConnectorRoleDefinitionIds
    environmentType: environmentType
    resourceNameSuffix: resourceNameSuffix
  }
}

//create a key vault
module keyvault 'modules/keyvault.bicep' = {
  name: keyVaultName
  params: {
    location: location
    keyVaultName: keyVaultName
    vnetId: databricks_vnet.outputs.vnetId
    privateLinkSubnetId: databricks_vnet.outputs.privateLinkSubnetId
  }
}
