param(
  [Parameter(Mandatory)]
  [ValidateNotNullOrEmpty()]
  [string] $resourceGroupName,
  
  [Parameter(Mandatory)]
  [ValidateNotNullOrEmpty()]
  [string] $storageAccountName
)

Describe 'parameters' {
  It 'resource group name should not be empty' {
    $resourceGroupName | Should -Not -BeNullOrEmpty
  }
  It 'storage account Name should not be empty' {
    $storageAccountName | Should -Not -BeNullOrEmpty
  }
}