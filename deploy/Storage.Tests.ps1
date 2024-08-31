param(
  [Parameter(Mandatory)]
  [ValidateNotNullOrEmpty()]
  [string] $HostName
)

Describe 'storage account' {

It 'Reaches storage over the internet' {
      $request = [System.Net.WebRequest]::Create("https://$HostName.dfs.core.windows.net/")
      $request.AllowAutoRedirect = $false
      $request.GetResponse().StatusCode |
        Should -Be 200 -Because "the storage is reachable over public internet"
    }
}