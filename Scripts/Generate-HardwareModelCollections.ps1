$ProviderMachineName = "siteserver.example.com"
$SiteCode = "ABC"

# Install-Module SQLServer

$allmodels = Invoke-Sqlcmd -ServerInstance $ProviderMachineName -Database "CM_$SiteCode" -Query "Select distinct Model0 from dbo.v_GS_COMPUTER_SYSTEM"
Foreach($model in $allmodels){
  IF(!(Get-CMDeviceCollection -Name $model.Model0)){
  Write-Output "No collection found for $($model.Model0)"
  New-CMDeviceCollection -Name $($model.Model0) -LimitingCollectionName "All Systems" -RefreshType Periodic
  $queryExp = 'select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System inner join SMS_G_System_COMPUTER_SYSTEM on SMS_G_System_COMPUTER_SYSTEM.ResourceId = SMS_R_System.ResourceId where SMS_G_System_COMPUTER_SYSTEM.Model like ' + '"' + "%$($model.Model0)%" + '"'
  Add-CMDeviceCollectionQueryMembershipRule -CollectionName $($Model.Model0) -RuleName $($Model.Model0) -QueryExpression $queryExp
  }
}
