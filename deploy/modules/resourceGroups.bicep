targetScope = 'subscription'

@description('environment type')
param environmentType string

@description('resource name prefix')
param resourceNameSuffix string

@description('location of the resource groups')
param location string

@description('name of the databricks resource group')
var managedResourceGroupName = 'databricks-rg-${environmentType}-${resourceNameSuffix}'

resource managedResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: managedResourceGroupName
  location: location
}

output managedResourceGroupName string = managedResourceGroup.name
output managedResourceGroupId string = managedResourceGroup.id
