#Discovery Script for SCCM Configuration Item
#If updates are returned (count > 0), display the toast
#Credit goes to @jgkps (I made slight modifications to only show available updates)

$VisibleUpdates = Get-CimInstance -Namespace Root\ccm\clientSDK -Class CCM_softwareupdate | Where-Object {($_.useruiexperience -eq $true) -and ($_.deadline -ne '')}
$VisibleUpdates.Name.Count
