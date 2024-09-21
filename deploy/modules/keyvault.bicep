param location string
param keyVaultName string
param privateLinkSubnetId string
param vnetId string

@description('Specifies the SKU to use for the key vault.')
param keyVaultSku object = {
  name: 'standard'
  family: 'A'
}

var keyvaultManagedIdentityName = 'keyvaultManagedIdentity'
var roleAssignmentName = guid(keyVault.id, managedIdentity.id, keyVaultAdministratorRoleDefinition.id)
var keyvaultEndpointName = 'hallinc-keyvault-endpoint'
var keyvaultLinkName = 'hallinc-keyvault-link'
var keyvaultDnsZoneName = 'hallinc-keyvault-dns-zone'
var keyvaultDnsGroupName = 'hallinc-keyvault-dns-zone-group'

resource keyVault 'Microsoft.KeyVault/vaults@2021-10-01' = {
  name: keyVaultName
  location: location
  properties: {
    enableRbacAuthorization: true
    tenantId: tenant().tenantId
    sku: keyVaultSku
  }
}

resource keyvaultEndpoint 'Microsoft.Network/privateEndpoints@2022-01-01' = {
  name: keyvaultEndpointName
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: keyvaultLinkName
        properties: {
          privateLinkServiceId: resourceId('Microsoft.KeyVault/vaults', keyVaultName)
          groupIds: [
            'vaults'
          ]
        }
      }
    ]
    subnet: {
      id: privateLinkSubnetId
    }
  }
}

resource keyvaultDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: keyvaultDnsZoneName
  location: 'global'
  dependsOn: [
    keyVault
  ]
}

resource keyvaultDnsZoneNameLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: keyvaultDnsZone
  name: '${keyvaultDnsZoneName}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}

resource keyvaultDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-11-01' = {
  name: keyvaultDnsGroupName
  parent: keyvaultEndpoint
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'keyvaultConfig'
        properties: {
          privateDnsZoneId: keyvaultDnsZone.id
        }
      }
    ]
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
