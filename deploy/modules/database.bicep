@description('The Azure region into which the resources should be deployed')
param location string
@description('The name of the SQL server')
param sqlServerName string
@description('The name of the SQL database')
param sqlDatabaseName string
@description('The administrator login username for the SQL server')
param sqlServerAdministratorLogin string
@description('The administrator login password for the SQL server')
@secure()
param sqlServerAdministratorLoginPassword string
@description('configuration for database')
param environmentConfiguration object
@description('The type of environment to deploy')
param environmentType string
param databaseEndpointName string
param databaseLinkName string
param privateLinkSubnetId string
param vnetId string

@description('param to control dns zone link deployment. set false when redeploying')
param createDnsZoneLink bool = false

var sqlDatabaseConnectionString = '''
  Server=tcp:${sqlServer.properties.fullyQualifiedDomainName},1433;
  Initial Catalog=${sqlDatabase.name};
  Persist Security Info=False;
  User ID=${sqlServerAdministratorLogin};
  Password=${sqlServerAdministratorLoginPassword};
  MultipleActiveResultSets=False;
  Encrypt=True;
  TrustServerCertificate=False;
  Connection Timeout=30;
'''

var databaseDnsZoneName = 'privatelink${environment().suffixes.sqlServerHostname}'
var databaseDnsGroupName = 'hallinc-storage-dns-zone'

resource sqlServer 'Microsoft.Sql/servers@2022-05-01-preview' = {
  name: sqlServerName
  location: location
  properties: {
    administratorLogin: sqlServerAdministratorLogin
    administratorLoginPassword: sqlServerAdministratorLoginPassword
  }
}

resource sqlDatabase 'Microsoft.Sql/servers/databases@2022-05-01-preview' = {
  parent: sqlServer
  name: sqlDatabaseName
  location: location
  sku: environmentConfiguration[environmentType].sqlDatabase.sku
  properties: environmentConfiguration[environmentType].sqlDatabase.properties
}

resource sqlServerFirewallRule 'Microsoft.Sql/servers/firewallRules@2022-05-01-preview' = {
  parent: sqlServer
  name: 'AllowAllAzureIps'
  properties: {
    endIpAddress: '0.0.0.0'
    startIpAddress: '0.0.0.0'
  }
}

resource databaseEndpoint 'Microsoft.Network/privateEndpoints@2022-01-01' = if (createDnsZoneLink) {
  name: databaseEndpointName
  location: location
  dependsOn: [
    databaseDnsZone
  ]
  properties: {
    privateLinkServiceConnections: [
      {
        name: databaseLinkName
        properties: {
          privateLinkServiceId: sqlServer.id
          groupIds: [
            'sqlServer'
          ]
        }
      }
    ]
    subnet: {
      id: privateLinkSubnetId
    }
  }
}

resource databaseDnsZone 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: databaseDnsZoneName
  location: 'global'
  dependsOn: [
    sqlServer
  ]
}

resource databaseDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-11-01' = {
  name: databaseDnsGroupName
  parent: databaseEndpoint
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'databaseConfig'
        properties: {
          privateDnsZoneId: databaseDnsZone.id
        }
      }
    ]
  }
}

resource DatabaseDnsZoneNameLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: databaseDnsZone
  name: '${databaseDnsZoneName}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}

output sqlServerFullyQualifiedDomainName string = sqlServer.properties.fullyQualifiedDomainName
output sqlDatabaseName string = sqlDatabase.name
output sqlDatabaseConnectionString string = sqlDatabaseConnectionString
