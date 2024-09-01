@description('The Azure region into which the resources should be deployed.')
param location string = resourceGroup().location

@description('The type of environment (dev or prod.')
@allowed([
  'Test'
  'Production'
])
param environmentType string

@description('A unique suffix to add to resource names that need to be globally unique.')
@maxLength(13)
param resourceNameSuffix string = uniqueString(resourceGroup().id)

var storageAccountName = 'hallincst${resourceNameSuffix}'
var environmentConfiguration = {
  Test: {
    storageAccountType: 'Standard_LRS'
    properties: {
      isHnsEnabled: true
    }
  }
  Production: {
    storageAccountType: 'Premium_LRS'
    properties: {
      isHnsEnabled: null
    }
  }
}

// create a storage account resource with hiearchical namespace enabled
resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: environmentConfiguration[environmentType].storageAccountType
  }
  kind: 'StorageV2'
  properties: environmentConfiguration[environmentType].properties
}

output storageAccountName string = storageAccount.name

// commented for to run test pipeline
