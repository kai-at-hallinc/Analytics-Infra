param location string
param disablePublicIp bool
param workspaceName string

@description('The pricing tier of workspace.')
@allowed([
  'trial'
  'standard'
  'premium'
])
param pricingTier string
param vnetId string
param publicSubnetName string = 'public-subnet'
param privateSubnetName string = 'private-subnet'

@description('The role definition Ids of the managed identity.see https://docs.microsoft.com/azure/role-based-access-control/built-in-roles.')
param managedIdentityRoleDefinitionIds array

@description('The role definition Ids of the databricks connector.https://docs.microsoft.com/azure/role-based-access-control/built-in-roles.')
param databricksConnectorRoleDefinitionIds array

@description('The name of the managed resource group.')
param managedResourceGroupName string

@description('An optional description to apply to each role assignment, such as the reason this managed identity needs to be granted the role.')
param roleAssignmentDescription string = 'this role is needed for machine interactions of the databricks workspace'

var databricksConnectorName = 'databricks-storage-connector-${uniqueString(workspaceName, resourceGroup().id)}'
var databricksConnectorType = 'SystemAssigned'
var userManagedIdentityName = 'databricks-user-managed-identity-${uniqueString(workspaceName, resourceGroup().id)}'

var managedIdentityRoleAssignments = [
  for roleDefinitionId in managedIdentityRoleDefinitionIds: {
    name: guid(databricksUserManagedIdentity.id, resourceGroup().id, roleDefinitionId)
    roleDefinitionId: roleDefinitionId
  }
]

var databricksConnectorRoleAssignments = [
  for roleDefinitionId in databricksConnectorRoleDefinitionIds: {
    name: guid(databricksStorageConnector.id, resourceGroup().id, roleDefinitionId)
    roleDefinitionId: roleDefinitionId
  }
]

resource workspace 'Microsoft.Databricks/workspaces@2024-05-01' = {
  name: workspaceName
  location: location
  sku: {
    name: pricingTier
  }
  properties: {
    parameters: {
      customVirtualNetworkId: {
        value: vnetId
      }
      customPublicSubnetName: {
        value: publicSubnetName
      }
      customPrivateSubnetName: {
        value: privateSubnetName
      }
      enableNoPublicIp: {
        value: disablePublicIp
      }
    }
    managedResourceGroupId: managedResourceGroup.id
  }
}

resource managedResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  scope: subscription()
  name: managedResourceGroupName
}

resource databricksStorageConnector 'Microsoft.Databricks/accessConnectors@2024-05-01' = {
  name: databricksConnectorName
  location: location
  tags: {}
  identity: {
    type: databricksConnectorType
  }
  properties: {}
}

resource databricksUserManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: userManagedIdentityName
  location: location
  tags: {}
}

resource managedIdentityRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = [
  for roleAssignment in managedIdentityRoleAssignments: {
    name: roleAssignment.name
    scope: resourceGroup()
    properties: {
      description: roleAssignmentDescription
      principalId: databricksUserManagedIdentity.properties.principalId
      roleDefinitionId: subscriptionResourceId(
        'Microsoft.Authorization/roleDefinitions',
        roleAssignment.roleDefinitionId
      )
      principalType: 'ServicePrincipal'
    }
  }
]

resource databricksConnectorRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = [
  for roleAssignment in databricksConnectorRoleAssignments: {
    name: roleAssignment.name
    scope: resourceGroup()
    properties: {
      description: roleAssignmentDescription
      principalId: databricksStorageConnector.identity.principalId
      roleDefinitionId: subscriptionResourceId(
        'Microsoft.Authorization/roleDefinitions',
        roleAssignment.roleDefinitionId
      )
      principalType: 'ServicePrincipal'
    }
  }
]

output workspaceId string = workspace.id
output managedResourceGroupId string = managedResourceGroup.id
output databricksStorageConnectorId string = databricksStorageConnector.id

// TODO create key vault role assignment for databricsk managed identity
