# ClientSide Error Code
$FailedUpdates = Get-WmiObject “CCM_SoftwareBase" -Namespace "ROOT\ccm\ClientSDK" | Where-Object {$_.UpdateID -and $_.ErrorCode}

IF($FailedUpdates){
    Foreach($Update in $FailedUpdates){
        $Update.ErrorCode
    }
}


#Discovery
$FailedUpdates = Get-WmiObject “CCM_SoftwareBase" -Namespace "ROOT\ccm\ClientSDK" | Where-Object {$_.UpdateID -and $_.ErrorCode}

IF($FailedUpdates){
    Foreach($Update in $FailedUpdates){
        Switch($Update.ErrorCode){
        2149842976 {Return "Non-Compliant"}
        2147944003 {Return "Non-Compliant"}
        default {Return "Compliant"}
        }
    }
}ELSE{
Return "Compliant"
}



#Remediation
$FailedUpdates = Get-WmiObject “CCM_SoftwareBase" -Namespace "ROOT\ccm\ClientSDK" | Where-Object {$_.UpdateID -and $_.ErrorCode}

IF($FailedUpdates){
    Foreach($Update in $FailedUpdates){
        ## Operation did not complete because there is no logged-on interactive user.
        IF($Update.ErrorCode -eq 2149842976){ 

            # Stop Windows Update Services
            Stop-Service wuauserv, bits, appidsvc
            Start-Sleep -Seconds 5
            Stop-Service cryptsvc -ErrorAction SilentlyContinue

            # Check for/remove previous run
            $softDistbackup = "C:\Windows\SoftwareDistribution.bak"
            IF(Test-Path $softDistbackup){
                Remove-Item $softDistbackup -Recurse -Force
            }

            # Rename SoftwareDistribution to $_.bak
            Rename-Item C:\Windows\SoftwareDistribution -NewName SoftwareDistribution.bak

            # Restart Windows Update Services
            Start-Service wuauserv, bits, appidsvc, cryptsvc
        }
        ## There is not enough space on the disk.
        IF($Update.ErrorCode -eq 2147942512){

            $UIResourceMgr = New-Object -ComObject UIResource.UIResourceMgr

            $Cache = $UIResourceMgr.GetCacheInfo()

            $Cache.GetCacheElements() |
            foreach {
                $Cache.DeleteCacheElement($_.CacheElementID)
            }
        }
        ## Fatal Eror during Installation - Rescan WSUS
        IF($Update.ErrorCode -eq 2147944003){
            # Reset Authorization with WSUS
            & C:\Windows\System32\wuauclt.exe /ResetAuthorization
            Start-Sleep -Seconds 10
            # Software Update Scan
            Invoke-WmiMethod -Namespace root\CCM -Class SMS_Client -Name TriggerSchedule -ArgumentList "{00000000-0000-0000-0000-000000000113}" | Out-Null
            Start-Sleep -Seconds 60
            # Update Deployment Evaluation
            Invoke-WmiMethod -Namespace root\CCM -Class SMS_Client -Name TriggerSchedule -ArgumentList "{00000000-0000-0000-0000-0000000000108}" | Out-Null
        }
    }
}


