$SoftwareBase = Get-WmiObject -Query "SELECT * FROM CCM_SoftwareBase" -Namespace "ROOT\ccm\ClientSDK"
$Updates = $SoftwareBase | Where-Object {$_.UpdateID}
$ErrorCodes = $Updates | % {$_.ErrorCode}

IF($ErrorCodes){
Foreach($Update in $Updates){
Switch($Update.ErrorCode){
2149842976 {Return "Non-Compliant"}
default {Return "Compliant"}
}
}
}Else{
Return "Compliant"
}