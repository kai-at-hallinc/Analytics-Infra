param location string
param resourceNameSuffix string

@description('The name of the storage account')
param storageAccountName string

@description('enable public network access to synapse workspace')
param synapsePublicNetworkAccess string

@description('use system assigned managed identity for synapse workspace')
param synapseManagedVirtualNetwork string

@description('synapse sql administrator login')
param synapseSqlAdministratorLogin string

@description('synapse sql administrator password')
@secure()
param synapseSqlAdministratorPassword string

@description('allow trusted services to synapse')
param trustedServiceBypassEnabled bool

var managedResourceGroupName = 'synapse-rg-${resourceNameSuffix}'
var synapseWorkspaceName = 'hallinc-synapse-${resourceNameSuffix}'
var synapseFilesystemName = 'synapse-data'

// synapse
resource storageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' existing = {
  name: storageAccountName
}

resource synapseWorkspace 'Microsoft.Synapse/workspaces@2021-06-01' = {
  name: synapseWorkspaceName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    defaultDataLakeStorage: {
      accountUrl: storageAccount.properties.primaryEndpoints.dfs
      createManagedPrivateEndpoint: true
      filesystem: synapseFilesystemName
      resourceId: storageAccount.id
    }
    managedResourceGroupName: managedResourceGroupName
    managedVirtualNetwork: synapseManagedVirtualNetwork
    publicNetworkAccess: synapsePublicNetworkAccess
    sqlAdministratorLogin: synapseSqlAdministratorLogin
    sqlAdministratorLoginPassword: synapseSqlAdministratorPassword
    trustedServiceBypassEnabled: trustedServiceBypassEnabled
  }
}
