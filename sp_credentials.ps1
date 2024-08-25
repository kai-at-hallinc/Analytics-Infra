$githubOrganizationName='kai-at-hallinc'
$githubRepositoryName='Analytics-Infra'
$resourceGroupId='/subscriptions/a011ea95-c1fe-4125-9cef-82abcac7f740/resourceGroups/hallinc-rg-sandbox'

$applicationRegistrationDetails=$(az ad app create --display-name 'hallinc-github-workflow-sandbox')
$applicationRegistrationObjectId=$(echo $applicationRegistrationDetails | jq -r '.id')
$applicationRegistrationAppId=$(echo $applicationRegistrationDetails | jq -r '.appId')

$jsonString='{\"name\":\"hallinc-github-workflow-sandbox\",\"issuer\":\"https://token.actions.githubusercontent.com\",\"subject\":\"repo:${githubOrganizationName}/${githubRepositoryName}:ref:refs/heads/main\",\"audiences\":[\"api://AzureADTokenExchange\"]}'

az ad app federated-credential create ` 
   --id $applicationRegistrationObjectId `
   --parameters $jsonString
   
az ad sp create --id $applicationRegistrationObjectId

az role assignment create `
--assignee $applicationRegistrationAppId `
--role Contributor `
--scope $resourceGroupResourceId

echo "AZURE_CLIENT_ID: $appRegistrationAppId"
echo "AZURE_TENANT_ID: $(az account show --query tenantId --output tsv)"
echo "AZURE_SUBSCRIPTION_ID: $(az account show --query id --output tsv)"