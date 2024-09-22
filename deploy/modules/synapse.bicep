param location string

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

@secure()
param tenantId string

@description('The name of the managed resource group.')
param managedResourceGroupName string

@description('The name of the synapse workspace.')
param synapseWorkspaceName string

@description('The name of the synapse filesystem.')
param synapseFilesystemName string

@description('The object id of the workspace admin.')
param workspaceAdminObjectId string

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
    cspWorkspaceAdminProperties: {
      initialWorkspaceAdminObjectId: workspaceAdminObjectId
    }
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

resource synapseAdministrator 'Microsoft.Synapse/workspaces/administrators@2021-06-01' = {
  name: 'activeDirectory'
  parent: synapseWorkspace
  properties: {
    administratorType: 'Synapse Administrator'
    login: 'kai@hallinc.onmicrosoft.com'
    sid: workspaceAdminObjectId
    tenantId: tenantId
  }
}
