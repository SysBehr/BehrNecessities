#Discovery Script for SCCM Configuration Item
#If updates are returned (count > 0), display the toast
#Credit goes to @jgkps

$VisibleUpdates = Get-CimInstance -Namespace Root\ccm\clientSDK -Class CCM_softwareupdate | Where-Object {($_.useruiexperience -eq $true)}
$VisibleUpdates.Name.Count
