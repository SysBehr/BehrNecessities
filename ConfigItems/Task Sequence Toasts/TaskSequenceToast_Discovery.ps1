## Displays a Windows 10 Toast Notification for Task Sequences
## SCCM Configuration Item Discovery Script
## Set the Compliance setting as an Integer equaling Zero. There is handling for Required vs Available count in the Remediation script.
# Author: Colin Wilkins @sysBehr
# Modified: 08/06/2019
# Version: 1.0

$softwareCenter = New-Object -ComObject "UIResource.UIResourceMgr"

$AvailableTSList = $Softwarecenter.GetAvailableApplications() | Where-Object {$_.IsAssigned -ne 1}
$RequiredTSList = $Softwarecenter.GetAvailableApplications() | Where-Object {$_.IsAssigned -eq 1}

Return ($AvailableTSList.Name.Count + $RequiredTSList.Name.Count)
