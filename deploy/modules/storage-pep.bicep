param storageEPName string
param storageAccountId string
param subnetId string
param dnsZoneName string
param privateZoneConfigName string
param privateDnsZoneId string

resource storageEndpoint 'Microsoft.Network/privateEndpoints@2023-11-01' = {
  name: storageEPName
  location: 'swedencentral'
  properties: {
    privateLinkServiceConnections: [
      {
        name: storageEPName
        properties: {
          privateLinkServiceId: storageAccountId
          groupIds: [
            'dfs'
          ]
        }
      }
    ]
    customNetworkInterfaceName: '${storageEPName}-nic'
    subnet: {
      id: subnetId
    }
  }
}

resource dnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-11-01' = {
  name: dnsZoneName
  parent: storageEndpoint
  properties: {
    privateDnsZoneConfigs: [
      {
        name: privateZoneConfigName
        properties: {
          privateDnsZoneId: privateDnsZoneId
        }
      }
    ]
  }
}
