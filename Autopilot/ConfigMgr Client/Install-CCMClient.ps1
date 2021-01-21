## HOW THIS WORKS ##
# Save this script in a folder with an optional "offline" copy of ccmsetup.exe for the client installation. Package it for Intune deployment with the Intune Win32 App Packager
# It's reccomended to deploy this to All Users or a User Group for your Autopilot deployment if you set ESP app requirements, this way it installs as one of the last items
# during ESP. Adjust the Task execution timeout to what works best for your environment. If you use other parameters, feel free to add/modify the task action (https://docs.microsoft.com/en-us/mem/configmgr/core/clients/deploy/about-client-installation-properties)
# NOTE: The task name and location is imporant as this is mimicing a native scheduled task created (and deleted by subsequent executions) by the CCM client install if setup fails.
# this may be deprecated in a later version of MEMCM CB, so use at your own risk. Alternatively, you could probably use this with the detection as a Proactive Remediation, OR, use
# Proactive Remediations to clean up the task installer if you don't feel comfortable mimicking the ConfigMgr Client Rety task does.

## Future Improvements to make to this script:
#  - Make sure the task doesn't inadvertantly launch during ESP if there's a reboot during any phase after the payload is dropped.
#    - check if ESP is still running, if so, postpone task execution until it completes. (check for WWAHost.exe?)
#  - If defaultuser0 is still logged in, prevent task execution ^
#  - Add AAD Token Authentication parameters if not using PKI (though I am unsure if this will work to auth against the CMG)

# Force script to use TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Replace this with your CMG URL from Cloud Management Settings
$CMG_url = "https://yourcmgurl.domain.com/CCM_Proxy_MutualAuth/#########"

# Replace this with an Internal MP
$MP_url = "https://internalmp.domain.com"

# Replace this with your PKI CA Issuer (if no PKI, I don't know if you'll be able to do the dynamic ccmsetup download)
$CA_path = "CN=YOUR-CERT-ISSUER-CA, DC=domain, DC=com"

# Replace this with your Site Code
$SiteCode = "ABC"

# Minutes to wait for first Scheduled Task Execution. It is reccomended to give it at least 1 minute.
# NOTE: After an Autopilot Deployment, the default Windows Sleep settings on battery is 4 minutes, AC power is 10 minutes.
# This can cause the task execution to be missed if -StartWhenAvailable is not flagged on the task settings.
$Minutes = 1

## End of Parameters ##

# Get Client certificates for CMG authentication - In my environment, I'm using Intune NDES to deploy certificates via SCEP for Client Authentication
$certs = ((Get-ChildItem Cert:\LocalMachine\My) | ? {$_.EnhancedKeyUsageList -like '*Client Authentication*' -and $_.Issuer -eq $CA_path})

# Create the temp directory for downloading CCMSetup. This should get cleaned up by Storage Sense or cleanmgr.exe
IF(!(Test-Path C:\Windows\Temp\CCMsetup)){
New-Item -ItemType Directory -Path C:\Windows\Temp\CCMsetup
}

IF($certs){
    Foreach($cert in $certs){
        Try{
            $ccmsetup = Invoke-WebRequest -uri "$CMG_url/CCM_Client/ccmsetup.exe" -Certificate $cert -OutFile "C:\Windows\Temp\CCMSetup\ccmsetup.exe"
        }Catch{}
            IF(Test-Path C:\Windows\Temp\CCMSetup\ccmsetup.exe){
            break
        }
        break
    }
}Else{
# allows local fallback for ccmsetup.exe if you aren't using internal PKI
    IF(Test-Path .\ccmsetup.exe){
        Copy-Item .\ccmsetup.exe C:\Windows\Temp\CCMsetup\ccmsetup.exe -Force
    }
}

# Create the Scheduled Task installer
$A = New-ScheduledTaskAction -Execute C:\Windows\Temp\CCMSetup\ccmsetup.exe -Argument "CCMHOSTNAME=$CMG_url SMSSiteCode=$SiteCode SMSMP=$MP_url /NOCRLCHECK /USEPKICERT"
$T = New-ScheduledTaskTrigger -Daily -At ([System.DateTime]::Now).AddMinutes($Minutes)
[Array]$T += New-ScheduledTaskTrigger -AtLogOn
$P = New-ScheduledTaskPrincipal "NT Authority\System"
$S = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
$task = New-ScheduledTask -Action $A -Trigger $T -Principal $P -Settings $S
Register-ScheduledTask -TaskName "Configuration Manager Client Retry Task" -InputObject $Task -TaskPath 'Microsoft\Microsoft\Configuration Manager'
