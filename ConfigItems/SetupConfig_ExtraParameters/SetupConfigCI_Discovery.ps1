# Note: These should be created as separate settings for the CI - modify the remdiation script to replace as many parameters as you need to set/enforce.

# Priority Discovery

IF(Get-Item "$env:SystemDrive\Users\Default\AppData\Local\Microsoft\Windows\WSUS\SetupConfig.ini" -ErrorAction SilentlyContinue)
{
$setupfile = (Get-Content C:\Users\Default\Appdata\Local\Microsoft\Windows\WSUS\SetupConfig.ini)

Foreach($line in $setupfile){
If($line -like 'Priority*'){return $line.replace("Priority=","")}
}
Return "NonCompliant"
}

# Compat Discovery

IF(Get-Item "$env:SystemDrive\Users\Default\AppData\Local\Microsoft\Windows\WSUS\SetupConfig.ini" -ErrorAction SilentlyContinue)
{
$setupfile = (Get-Content C:\Users\Default\Appdata\Local\Microsoft\Windows\WSUS\SetupConfig.ini)

Foreach($line in $setupfile){
If($line -like 'Compat*'){return $line.replace("Compat=","")}
}
Return "NonCompliant"
}

# BitLocker Discovery

IF(Get-Item "$env:SystemDrive\Users\Default\AppData\Local\Microsoft\Windows\WSUS\SetupConfig.ini" -ErrorAction SilentlyContinue)
{
$setupfile = (Get-Content C:\Users\Default\Appdata\Local\Microsoft\Windows\WSUS\SetupConfig.ini)

Foreach($line in $setupfile){
If($line -like 'BitLocker*'){return $line.replace("BitLocker=","")}
}
Return "NonCompliant"
}
