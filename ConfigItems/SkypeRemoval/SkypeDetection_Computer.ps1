$skypeShortcut = Get-Item "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Skype for Business.lnk" -ErrorAction SilentlyContinue
$skypeExtra = Get-Item "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Microsoft Office Tools\Skype for Business Recording Manager.lnk" -ErrorAction SilentlyContinue

$skypeIE64 = Get-ChildItem "HKLM:\Software\Microsoft\Internet Explorer\Extensions\*" | % { Get-ItemProperty $_.Name.Replace("HKEY_LOCAL_MACHINE","HKLM:") | Where-Object {$_.'(default)' -eq "Lync Click to Call"} }
$skypeIE86 = Get-ChildItem "HKLM:\Software\WOW6432Node\Microsoft\Internet Explorer\Extensions\*" | % { Get-ItemProperty $_.Name.Replace("HKEY_LOCAL_MACHINE","HKLM:") | Where-Object {$_.'(default)' -eq "Lync Click to Call"} }

$skypeExtm = Get-Item "HKLM:\SOFTWARE\Microsoft\Office\Outlook\Addins\UCAddin.LyncAddin.1" -ErrorAction SilentlyContinue

IF($skypeShortcut -or $skypeExtra -or $skypeIE64 -or $skypeIE86 -or $skypeExtm){
Return "Non-Compliant"
}Else{
Return "Compliant"
}
