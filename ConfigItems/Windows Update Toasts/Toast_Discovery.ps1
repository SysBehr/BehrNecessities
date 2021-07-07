#Discovery Script for SCCM Configuration Item
#If updates are returned (count > 0), display the toast
#Credit goes to @jgkps

$VisibleUpdates = Get-CimInstance -Namespace Root\ccm\clientSDK -query "SELECT Name FROM CCM_softwareupdate WHERE UserUIExperience = 1"
$VisibleUpdates.Name.Count
