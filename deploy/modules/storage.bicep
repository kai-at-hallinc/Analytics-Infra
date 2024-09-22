param storageAccountName string
param storageAccountBlobContainerName string
param location string
param environmentType string
param environmentConfiguration object
param privateLinkSubnetId string
param vnetId string

var storageEndpointName = 'hallinc-storage-endpoint'
var storageLinkName = 'hallinc-storage-link'
var storageDnsZoneName = 'privatelink${environment().suffixes.storage}'
var storageDnsGroupName = 'hallinc-storage-dns-zone'

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
      properties: environmentConfiguration[environmentType].blobContainers.properties
    }
  }
}

resource storageEndpoint 'Microsoft.Network/privateEndpoints@2022-01-01' = {
  name: storageEndpointName
  location: location
  dependsOn: [
    storageDnsZone
  ]
  properties: {
    privateLinkServiceConnections: [
      {
        name: storageLinkName
        properties: {
          privateLinkServiceId: storageAccount.id
          groupIds: [
            'dfs'
          ]
        }
      }
    ]
    subnet: {
      id: privateLinkSubnetId
    }
  }
}

resource storageDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: storageDnsZoneName
  location: 'global'
  dependsOn: [
    storageAccount
  ]
}

resource storageDnsZoneNameLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: storageDnsZone
  name: '${storageDnsZoneName}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}

resource storageDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-11-01' = {
  name: storageDnsGroupName
  parent: storageEndpoint
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'storageConfig'
        properties: {
          privateDnsZoneId: storageDnsZone.id
        }
      }
    ]
  }
}

output storageAccountName string = storageAccount.name
output storageAccountBlobContainerName string = storageAccount::blobService::storageAccountBlobContainer.name
