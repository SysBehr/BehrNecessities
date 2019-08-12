#Don't be fooled by the console not showing distribution status after running this... because it doesn't.

$AppsToRedistribute = Get-CMapplication -Fast | Where-Object {$_.DateCreated -ge (Get-Date).AddDays(-3)}

Foreach($App in $AppsToRedistribute){
$deploymentTypes = Get-CMDeploymentType -ApplicationName $app.LocalizedDisplayName
    Foreach($DeploymentType in $deploymentTypes){
    Update-CMDistributionPoint -ApplicationName $app.LocalizedDisplayName -DeploymentTypeName $deploymentType.LocalizedDisplayName
    }
}

