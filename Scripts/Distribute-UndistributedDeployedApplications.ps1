$DPGroupName = "Application Deployment Distribution Points"

$UndistributedContent = Get-CMDistributionStatus | Where-Object {$_.NumberErrors -eq 0 -and $_.NumberInProgress -eq 0 -and $_.NumberSuccess -eq 0}

$ContenttoDistribute = @()

Foreach($App in $UndistributedContent){
IF(Get-CMDeployment -SoftwareName $App.SoftwareName){
Write-Output "Found deployment for $($App.SoftwareName)"
$ContenttoDistribute += $App
}Else{
Write-Output "No deployment found for $($App.SoftwareName)"
}
}

Write-Output "Found $($ContenttoDistribute.Count) undistributed applications/packages that are deployed"

Foreach($ApptoDistribute in $ContenttoDistribute){
Write-Host "Distributing $($ApptoDistribute.SoftwareName)"
Start-CMContentDistribution -ApplicationName $ApptoDistribute.SoftwareName -DistributionPointGroupName $DPGroupName
}
