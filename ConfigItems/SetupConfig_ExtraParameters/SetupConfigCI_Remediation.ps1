#Variable for ini file path
$iniFilePath = "$env:SystemDrive\Users\Default\AppData\Local\Microsoft\Windows\WSUS\SetupConfig.ini"

#Variables for SetupConfig
$iniSetupConfigSlogan = "[SetupConfig]"
$iniSetupConfigKeyValuePair =@{"Priority"="Normal";"BitLocker"="AlwaysSuspend";"Compat"="IgnoreWarning";}

#Init SetupConfig content
$iniSetupConfigContent = @"
$iniSetupConfigSlogan
"@

#Build SetupConfig content with settings
foreach ($k in $iniSetupConfigKeyValuePair.Keys) 
{
    $val = $iniSetupConfigKeyValuePair[$k]

    $iniSetupConfigContent = $iniSetupConfigContent.Insert($iniSetupConfigContent.Length, "`r`n$k=$val")
}

IF(Test-Path $iniFilePath){
Remove-Item $iniFilePath -Force
}
#Write content to file 
New-Item $iniFilePath -ItemType File -Value $iniSetupConfigContent -Force