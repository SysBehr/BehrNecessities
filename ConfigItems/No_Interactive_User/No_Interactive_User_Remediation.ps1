Stop-Service wuauserv -Force

$badupdate = Get-ChildItem -Path C:\Windows\SoftwareDistribution\Download\ -Recurse -filter WindowsUpdateBox.exe
If($badupdate){
Remove-Item $badupdate.Directory -Recurse -Force
}

Start-Service wuauserv
