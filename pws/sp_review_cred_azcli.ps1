# variables

# too long string for params .)
$federatedCredentialParameters='{\"name\":\"analytics-infra-review\",\"issuer\":\"https://token.actions.githubusercontent.com\",\"subject\":\"repo:kai-at-hallinc/analytics-infra:pull_request\",\"audiences\":[\"api://AzureADTokenExchange\"]}'

$resourceGroup='/subscriptions/a011ea95-c1fe-4125-9cef-82abcac7f740/resourceGroups/hallinc-analytics-sandbox'

# application registration variables
$applicationRegistrationDetails = az ad app create --display-name $applicationRegistrationName | ConvertFrom-Json
$applicationRegistrationObjectId = $applicationRegistrationDetails.id
$applicationRegistrationAppId = $applicationRegistrationDetails.appId

# create federated credential
az ad app federated-credential create `
   --id $applicationRegistrationObjectId `
   --parameters $federatedCredentialParameters

# create service principal for registration
az ad sp create --id $applicationRegistrationObjectId

# give contributor role assignment
az role assignment create `
--role "Contributor" `
--assignee $applicationRegistrationAppId `
--scope $resourceGroup

# output variables
echo "AZURE_CLIENT_ID: $applicationRegistrationAppId"
echo "AZURE_TENANT_ID: $(az account show --query tenantId --output tsv)"
echo "AZURE_SUBSCRIPTION_ID: $(az account show --query id --output tsv)"

