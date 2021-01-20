[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

## HOW THIS WORKS ##
#Save this script in a folder with an "offline" copy of ccmsetup.exe for the client installation. Package it for Intune dpeloyment with the Intune Win32 App Packager

#Replace this with your CMG URL from Cloud Management Settings
$CMG_url = "https://yourcmgurl.domain.com/CCM_Proxy_MutualAuth/#########"
#Replace this with an Internal MP
$MP_url = "https://internalmp.domain.com"
#Replace this with your PKI CA Issuer (if no PKI, I don't know if you'll be able to do the dynamic ccmsetup download)
$CA_path = "CN=YOUR-CERT-ISSUER-CA, DC=domain, DC=com"
#Replace this with your Site Code
$SiteCode = "ABC"

$certs = ((Get-ChildItem Cert:\LocalMachine\My) | ? {$_.EnhancedKeyUsageList -like '*Client Authentication*' -and $_.Issuer -eq $CA_path})

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
Copy-Item .\ccmsetup.exe C:\Windows\Temp\CCMsetup\ccmsetup.exe -Force
}

$A = New-ScheduledTaskAction -Execute C:\Windows\Temp\CCMSetup\ccmsetup.exe -Argument "CCMHOSTNAME=$CMG_url SMSSiteCode=$SiteCode SMSMP=$MP_url /NOCRLCHECK /USEPKICERT"
$T = New-ScheduledTaskTrigger -Daily -At ([System.DateTime]::Now).AddMinutes(5)
[Array]$T += New-ScheduledTaskTrigger -AtLogOn
$P = New-ScheduledTaskPrincipal "NT Authority\System"
$S = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
$task = New-ScheduledTask -Action $A -Trigger $T -Principal $P -Settings $S
Register-ScheduledTask -TaskName "Configuration Manager Client Retry Task" -InputObject $Task -TaskPath 'Microsoft\Microsoft\Configuration Manager'
