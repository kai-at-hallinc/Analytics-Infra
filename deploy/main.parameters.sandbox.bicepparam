using './main.bicep'

@allowed([
  'Test'
  'Production'
])
param environmentType = ''
param sqlServerAdministratorLogin = ''
param sqlServerAdministratorLoginPassword = ''
param disablePublicIp = true
param databricksPricingTier = 'premium'

var test_setting = {
  storageAccountType: 'Standard_LRS'
    properties: {
      isHnsEnabled: true
      allowBlobPublicAccess: true
      networkAcls: {
        bypass: 'AzureServices, Logging, Metrics'
        defaultAction: 'Deny'
      }
    }
    blobContainers: {
      properties: {
        publicAccess: 'None'
      }
    }
    sqlDatabase: {
      properties: {
        collation: 'SQL_Latin1_General_CP1_CI_AS'
        autoPauseDelay: '30'
        freeLimitExhaustionBehavior: 'Pause'
        useFreeLimit: true
      }
      sku: {
        name: 'Basic'
        tier: 'basic'
      }
    }
}

var production_setting = {
  storageAccountType: 'Premium_LRS'
    properties: {
      isHnsEnabled: null
      networkAcls: {
        bypass: 'AzureServices, Logging, Metrics'
        defaultAction: 'Deny'
      }
    }

    blobContainers: {
      properties: {
        publicAccess: 'None'
      }
    }
    sqlDatabase: {
      properties: {
        collation: 'SQL_Latin1_General_CP1_CI_AS'
      }
      sku: {
        name: 'Standard'
        tier: 'Standard'
      }
    }
}
param environmentConfiguration = {
  Test: test_setting
  Production: production_setting
}

@description('list of role assignment to assign for user assigned managed identity')
param managedIdentityRoleDefinitionIds = [
  'b24988ac-6180-42a0-ab88-20f7382dd24c'
  '4633458b-17de-408a-b874-0445c86b69e6'
]

@description('list of role assignment to assign for databricks connector')
param databricksConnectorRoleDefinitionIds = [
  'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
]
  
