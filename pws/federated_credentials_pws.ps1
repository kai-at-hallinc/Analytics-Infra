# variables
$appRegistrationName = "hallinc-github-workflow"
$fedarationPolicy="repo:kai-at-hallinc/analytics-infra:ref:refs/heads/main"

# create an application registration in entraid
$appRegistrationObject= $(New-AzADApplication -DisplayName $appRegistrationName)

# get the application registration object details
$appRegistrationObjectId=$($appRegistrationObject.id)
$appRegistrationAppId=$($appRegistrationObject.appId)

# create a service principal
New-AzADServicePrincipal -ApplicationId $appRegistrationAppId

# get resource group id
$resourceGroup=$(az group show -n hallinc-rg-sandbox --query id -o tsv)

# assign the contributor role to the service principal
New-AzRoleAssignment `
-ApplicationId $appRegistrationAppId `
-RoleDefinitionName Contributor `
-Scope $resourceGroup `
-Description "The deployment workflow for the analytics-infra repository"

# create the federated credential
New-AzADAppFederatedCredential `
  -Name 'MyFederatedCredential' `
  -ApplicationObjectId $appRegistrationObjectId `
  -Issuer 'https://token.actions.githubusercontent.com' `
  -Audience 'api://AzureADTokenExchange' `
  -Subject $federationPolicy

# output variables for the GitHub actions
Write-Host "AZURE_CLIENT_ID: $appRegistrationAppId"
Write-Host "AZURE_TENANT_ID: $((Get-AzContext).Tenant.Id)"
Write-Host "AZURE_SUBSCRIPTION_ID: $((Get-AzContext).Subscription.Id)"
