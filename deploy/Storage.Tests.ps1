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

Describe 'Storage Account' {
  $storageAccount = Get-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName

  It 'storage account should exist' {
    $storageAccount | Should -Not -BeNullOrEmpty
  }
  It 'storage account should be online' {
    $storageAccount.ProvisioningState | Should -Be 'Succeeded'
  }
  It 'storage account should have Hns enabled' {
    $storageAccount.EnableHierarchicalNamespace | Should -Be $true
  }
  It 'container can be created' {
    $containerName = 'test'
    $container = New-AzStorageContainer -Name $containerName -Context $storageAccount.Context
    $container.name | Should -Be $containerName
  }
}