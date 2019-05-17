Stop-Service WUAUSERV
(Get-ChildItem -Path C:\Windows\SoftwareDistribution\Download\ -Filter "WindowsUpdateBox.exe" -Recurse).DirectoryName | Remove-Item -Recurse -Force
Start-Service WUAUSERV