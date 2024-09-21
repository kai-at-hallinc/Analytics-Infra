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

@description('The role definition Ids of the databricks connector.see https://docs.microsoft.com/azure/role-based-access-control/built-in-roles.')
param databricksConnectorRoleDefinitionIds array

var managedResourceGroupName = 'databricksrg-${workspaceName}${uniqueString(workspaceName, resourceGroup().id)}'
var trimmedMRGName = substring(managedResourceGroupName, 0, min(length(managedResourceGroupName), 90))
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

@description('An optional description to apply to each role assignment, such as the reason this managed identity needs to be granted the role.')
param roleAssignmentDescription string = 'this role is needed for machine interactions of the databricks workspace'

resource workspace 'Microsoft.Databricks/workspaces@2024-05-01' = {
  name: workspaceName
  location: location
  sku: {
    name: pricingTier
  }
  properties: {
    managedResourceGroupId: resourceId(subscription().subscriptionId, 'resourceGroups', trimmedMRGName)
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
  }
}

resource databricksStorageConnector 'Microsoft.Databricks/accessConnectors@2024-05-01' = {
  name: databricksConnectorName
  location: location
  tags: {}
  identity: {
    type: databricksConnectorType
    userAssignedIdentities: {}
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

// TODO create key vault role assignment for databricsk managed identity
