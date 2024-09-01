param(
  [Parameter(Mandatory)]
  [ValidateNotNullOrEmpty()]
  [string] $resourceGroupName,
  
  [Parameter(Mandatory)]
  [ValidateNotNullOrEmpty()]
  [string] $storageAccountName
)

Describe 'Storage Account Tests' {
  $storageAccounts=az storage account list --resource-group $resourceGroupName | ConvertFrom-Json

  It 'storage account should exist' {
    $storageAccountNames = $storageAccounts | ForEach-Object { $_.name }
    $storageAccountNames | Should -Contain $storageAccountName
    }
}