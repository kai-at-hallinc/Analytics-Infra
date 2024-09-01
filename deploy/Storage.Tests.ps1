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

Describe 'Azure CLI Tests' {
  Context 'When connecting to Azure' {
      It 'Should connect to Azure successfully' {
          # Connect to Azure
          $connection = Connect-AzAccount -ErrorAction Stop
          
          # Verify the connection
          $connection | Should -Not -BeNullOrEmpty
      }
  }
}