param location string
param keyVaultName string
var keyvaultManagedIdentityName = 'keyvaultManagedIdentity'

@description('Specifies the SKU to use for the key vault.')
param keyVaultSku object = {
  name: 'standard'
  family: 'A'
}

var roleAssignmentName = guid(keyVault.id, managedIdentity.id, keyVaultAdministratorRoleDefinition.id)

resource keyVault 'Microsoft.KeyVault/vaults@2021-10-01' = {
  name: keyVaultName
  location: location
  properties: {
    enableRbacAuthorization: true
    tenantId: tenant().tenantId
    sku: keyVaultSku
  }
}

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: keyvaultManagedIdentityName
  location: location
}

resource keyVaultAdministratorRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  scope: subscription()
  name: '00482a5a-887f-4fb3-b363-3b7fe8e74483'
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: roleAssignmentName
  scope: keyVault
  properties: {
    roleDefinitionId: keyVaultAdministratorRoleDefinition.id
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
  dependsOn: [
    keyVaultAdministratorRoleDefinition
  ]
}
//TODO: create private endpoint for key vault
