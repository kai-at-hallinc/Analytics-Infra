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

# azure/login@v1 logged in by azcli. use cli commands

Describe 'test infrastructure' {
  
  Context 'storage account' {
      It 'storage accounts using azure cli' {
          $result = az storage account list --resource-group $resourceGroupName --query "[?name=='$storageAccountName']" -o tsv
          $result | Should -Not -BeNullOrEmpty
      }
      It 'storage aacount has IsHnsEnabled' {
          $result = az storage account show --name $storageAccountName --resource-group $resourceGroupName --query "isHnsEnabled" -o tsv
          $result | Should -Be 'true'
      }
      It 'container can be created' {
          $containerName = 'testcontainer'
          $result = az storage container create --name $containerName --account-name $storageAccountName
          $result | Should -Not -BeNullOrEmpty
      }
      # Teardown actions
      AfterAll {
        $containerName = 'testcontainer'
        az storage container delete --name $containerName --account-name $storageAccountName
    }
  }
}