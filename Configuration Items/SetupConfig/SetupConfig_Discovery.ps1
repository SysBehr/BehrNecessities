#Discovery SetupPriority

IF(Get-Item "$env:SystemDrive\Users\Default\AppData\Local\Microsoft\Windows\WSUS\SetupConfig.ini" -ErrorAction SilentlyContinue)
{
$setupfile = (Get-Content C:\Users\Default\Appdata\Local\Microsoft\Windows\WSUS\SetupConfig.ini)

Foreach($line in $setupfile){
If($line -like 'Priority*'){return $line.replace("Priority=","")}
}
Return "NonCompliant"
}

#Discovery Compat

IF(Get-Item "$env:SystemDrive\Users\Default\AppData\Local\Microsoft\Windows\WSUS\SetupConfig.ini" -ErrorAction SilentlyContinue)
{
$setupfile = (Get-Content C:\Users\Default\Appdata\Local\Microsoft\Windows\WSUS\SetupConfig.ini)

Foreach($line in $setupfile){
If($line -like 'Compat*'){return $line.replace("Compat=","")}
}
Return "NonCompliant"
}

#Discovery Bitlocker

IF(Get-Item "$env:SystemDrive\Users\Default\AppData\Local\Microsoft\Windows\WSUS\SetupConfig.ini" -ErrorAction SilentlyContinue)
{
$setupfile = (Get-Content C:\Users\Default\Appdata\Local\Microsoft\Windows\WSUS\SetupConfig.ini)

Foreach($line in $setupfile){
If($line -like 'BitLocker*'){return $line.replace("BitLocker=","")}
}
Return "NonCompliant"
}
