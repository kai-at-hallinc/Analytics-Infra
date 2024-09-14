$applicationRegistrationDetails=$(az ad app create --display-name 'hallinc-github-workflow-sandbox')
$applicationRegistrationObjectId=$(Write-Output $applicationRegistrationDetails | jq -r '.id')
$applicationRegistrationAppId=$(Write-Output $applicationRegistrationDetails | jq -r '.appId')

$jsonString='{\"name\":\"hallinc-github-workflow-sandbox\",\"issuer\":\"https://token.actions.githubusercontent.com\",\"subject\":\"repo:${githubOrganizationName}/${githubRepositoryName}:ref:refs/heads/main\",\"audiences\":[\"api://AzureADTokenExchange\"]}'

az ad app federated-credential create `
   --id $applicationRegistrationObjectId `
   --parameters $jsonString
   
az ad sp create --id $applicationRegistrationObjectId

az role assignment create `
--assignee $applicationRegistrationAppId `
--role Contributor `
--scope $resourceGroupId

Write-Output "AZURE_CLIENT_ID: $appRegistrationAppId"
Write-Output "AZURE_TENANT_ID: $(az account show --query tenantId --output tsv)"
Write-Output "AZURE_SUBSCRIPTION_ID: $(az account show --query id --output tsv)"