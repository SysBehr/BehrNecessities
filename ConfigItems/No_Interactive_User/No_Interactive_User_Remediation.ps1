Stop-Service wuauserv
(Get-Item -Path C:\Windows\SoftwareDistribution\Download\*) | Remove-Item -Force -Recurse
Start-Service wuauserv