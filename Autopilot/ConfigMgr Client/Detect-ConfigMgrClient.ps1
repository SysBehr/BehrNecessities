# ConfigMgr Client detection for the Autopilot Scheduled Task installer

#Set your expected Site Code
$SiteCode = "ABC"

# Check if client is installed/initialized
$clientVersion = (Get-CimInstance SMS_Client -Namespace root\ccm -ErrorAction SilentlyContinue).ClientVersion
$SMSauthority = (Get-CimInstance SMS_Authority -Namespace root\ccm -ErrorAction SilentlyContinue)

# Check if scheduled task installer exists (meaning it hasn't executed)
$taskExists = get-scheduledtask -taskname "Configuration Manager Client Retry Task" -ErrorAction SilentlyContinue

# Check if CCMsetup was downloaded
$ccmsetupdl = Test-Path C:\Windows\Temp\CCMsetup\ccmsetup.exe

# Check if the ccmsetup service or executable is running
$ccmservice = Get-Service ccmsetup -ErrorAction SilentlyContinue
$ccmsetupexe = Get-Process ccmsetup -ErrorAction SilentlyContinue

## This part might be overkill...
# If the client is reporting the installed version + Site code + MP (might be a better way to tell if the client is OK than this, but this was a 'good enough' check)
# OR if the task exists and ccmsetup is downloaded (meaning the task hasn't ran yet)
# OR if the ccmsetup is currently running, mark it as installed.
#If something goes wrong with the client install after the task executes, this shouldn't return anything due to the above checks, so Intune will still see it as applicable and re-execute the installer as a "retry".
IF($clientVersion -and ($SMSauthority.Name -eq "SMS:$SiteCode" -and $SMSauthority.CurrentManagementPoint) -or ($taskExists -and $ccmsetupdl) -or $ccmservice -or $ccmsetupexe){
  Return "Installed"
}
