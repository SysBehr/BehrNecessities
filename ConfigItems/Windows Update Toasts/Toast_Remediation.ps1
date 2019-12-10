## Displays a Windows 10 Toast Notification for Windows Updates
## SCCM Configuration Item Remediation Script

## References
# Source Script/Idea: https://smsagent.wordpress.com/2018/06/15/using-windows-10-toast-notifications-with-configmgr-application-deployments/
# Options for audio: https://docs.microsoft.com/en-us/uwp/schemas/tiles/toastschema/element-audio#attributes-and-elements
# Toast content schema: https://docs.microsoft.com/en-us/windows/uwp/design/shell/tiles-and-notifications/toast-schema
#
# Author: Colin Wilkins @SysBehr
# Assistance from @jgkps on the Windows Admins Slack
# Modified: 10/03/2019
# Version: 3.6

# Required parameters
$Title = "Updates are ready to install"
$ITdept = "Your Company Information Technology"
$SoftwarecenterShortcut = "softwarecenter:page=Updates"
$AudioSource = "ms-winsoundevent:Notification.Default"

# Base64 strings for populating toast images. Logo should be 48x48, Inline image (ex: IT/Company Logo) should be around 364(or longer)x100 to not display obnoxiously
$Base64LogoImage = "iVBORw0KGgoAAAANSUhEUgAAADAAAAAwCAYAAABXAvmHAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAANySURBVGhD7Zg7aBRBGMfjK0qMeia+UgjRQstDMDYSQcSAgmhUEFGDhYhgk1LSaGFAwUIkoIXBgBqC0cqIGCsftY0GQQVRERQt4gOMqHf+/ptvjtO7i5fduYsL+4Mfc/fN7jczu7OvqUlISEjwTjabnY1rcZqFqocaxcXYgptwM67DZVhWh9juOIqtFqosNFSH+/AavsdSqO46HsB6270A6s6i2G+hykADDXgSR9Wa8QNHcAj78QrexMeouoBMJvOZ4gwusXQ5iFV2ACTWNOmgEx/VCuVXil5sw7m2WQHU6UxtwT78htr3E8VRnG6bVXYAJFUndFTFd+zGRqsuG/ZZiufwJ4pbmLK6ygyAhCmO2ANlpnxEsdqqQkMO3W2eW84nFLrY/Q+AZDryD4O02ewNnGNVkSFXCu8psQ3ivH6DnwGQSHP+apByvPMzrMob5NQBuq8GGMRLleBtAB3KZtMm0pFn/1o8hReLeJk2vlA6og+AJA0k1d1GF6yPOb8Ky8XLAHSfF90Wigy51uOOCdQZ34nLbZdwkEDzcpQzoPv8pG+VUw6d1uuB6LVQvKDjercRbRaKD3Rat069fOn9peTrwX8LndYrsRixULyg43qfF0MWihd0XB8jot9CVYe2O/EdNluofNhpJbfPN5SHLVR1aH+Q9kWrheIFAxi2AaQtFC8YwAsbwHwLxQc6rVfsX/jKQvGCjm9H0WeheEHHtSAg2i0UH+h0E45xDXygrLVwOEjQjHvwEO6ewA22S2TI5b6JuywUHpIcHM9VFitst9CQI41aqXiL8ywcHpLkBsAp1WLUJbxQxBMY6VuZ/etp4yml2GXhaJAoGACJ3Ye2PrzrrNob5JxFG7eDFjggFo4OydwZ6KEBLXkILYEstE0iQy4dedf5uxjtws2HZG4AWsfUopPWOHVG9JRssc1CQ440udy0Ueejz/t8SJgbgP3XE1KLtUJPyh5sCjaeBOzjVuDc0qKuI39H3kHSPwYg+K2vtSPoVqW15KKFr21Y8ghStwD1hNW2Yyh0t/FzwRaD5AUDcBBbhKcxf3ldZ+UZ0+IO5QDlIA7blFNdAP/1kOpCv1Pmb2ig5AAc1Gn5ZS8OoI5oUej0awotrbej/+lSDBrStBDHLPRP2LYR1+BGbEU9nKbmlZiGNd/VgZkWSkhISPBFTc1vc9xaMWyYdnsAAAAASUVORK5CYII="
#InlineImage is optional but looks real nice when you use a company logo
$Base64InlineImage = ""

<#
#Use this to create a Base64 image string and copy it to the clipboard for pasting into the Base64 variables
$File = "C:\image.png"
$Image = [System.Drawing.Image]::FromFile($File)
$MemoryStream = New-Object System.IO.MemoryStream
$Image.Save($MemoryStream, $Image.RawFormat)
[System.Byte[]]$Bytes = $MemoryStream.ToArray()
$Base64 = [System.Convert]::ToBase64String($Bytes)
$Image.Dispose()
$MemoryStream.Dispose()
$Base64 | Set-Clipboard
#>

# list all visible updates currently available for installation on the system, sorted by earliest deadline
$DeadlinedUpdates = @(Get-CimInstance -Namespace Root\ccm\clientSDK -Query "SELECT * FROM CCM_softwareupdate WHERE UserUIExperience = 1 AND Deadline IS NOT NULL" -ErrorAction SilentlyContinue| Sort-Object -Property Deadline)
$AvailableUpdates = @(Get-CimInstance -Namespace Root\ccm\clientSDK -Query "SELECT * FROM CCM_softwareupdate WHERE UserUIExperience = 1 AND Deadline IS NULL" -ErrorAction SilentlyContinue)

# Get Pending Reboot status
$rebootinfo = Invoke-CimMethod -ClassName CCM_ClientUtilities -Namespace root\ccm\clientsdk -MethodName DetermineIfRebootPending

# Do nothing if we don't have updates (just in case)
IF(-not $DeadlinedUpdates -and -not $AvailableUpdates){
Return
}

# Get deadlines
If($DeadlinedUpdates[0].deadline){

$updateDeadline = $DeadlinedUpdates[0].deadline

    # if the deadline specified by the update has passed, set $DeadLinePassed to $true
    if ( ($updateDeadline ) -lt (get-date) ) {
    $DeadLinePassed = $true
    $ShowDeadline = $false
    }
    elseif ( ( $updateDeadline ) -gt (get-date) ) {
    
        $TimeSpan = ( $updateDeadline ) - (get-date)
        $ShowDeadline = $true
    }
}

# Grammar is important
switch ($DeadlinedUpdates.Name.Count) {
    {$_ -gt 1} {$UpdatesText = "$($DeadlinedUpdates.Name.Count) Updates"}
    {$_ -eq 1} {$UpdatesText = "$($DeadlinedUpdates.Name.Count) Update"}
}

switch ($AvailableUpdates.Name.Count) {
    {$_ -gt 1} {$UpdatesAvailText = "$($AvailableUpdates.Name.Count) Updates"}
    {$_ -eq 1} {$UpdatesAvailText = "$($AvailableUpdates.Name.Count) Update"}
}


# if deadline has passed, update toast wording and calculate deadline timespan
If ($DeadlinePassed -and $DeadlinedUpdates) {
$TimeSpan = $updateDeadline - $updateDeadline
$AudioSource = "ms-winsoundevent:Notification.Reminder"
}Else{
}

IF($rebootinfo.RebootPending){
$rebootDeadline = $rebootinfo.RebootDeadline
$Title = "Updates require a system restart"
    switch ($DeadlinedUpdates.Name.Count) {
        {$_ -gt 1} {$Status = "require a restart:"}
        {$_ -eq 1} {$Status = "requires a restart:"}
    }
    $TimeSpan = $rebootDeadline - (Get-Date)
    $showDeadline = $false
}

$Deadline = ''
IF($showDeadline){
$Deadline = @"
<group>
    <subgroup>
        <text hint-style="caption" hint-align="center">Time Remaining:</text>
    </subgroup>
    <subgroup>
        <text hint-style="caption" hint-align="center">$($TimeSpan.Days) days $($TimeSpan.Hours) hours $($TimeSpan.Minutes) minutes</text>
    </subgroup>
</group>
"@
}

# Do some things with the returned updates so they stack for the XML. More than 13 updates breaks the toast, so truncate at 12.
IF($DeadlinedUpdates){
$GroupedDeadlinedUpdates = '<text hint-style="base" hint-align="left">' + $UpdatesText + ' Required' + '</text>`n'
Foreach($Update in $DeadlinedUpdates[0..9]){
$GroupedUpdate = @"
<text hint-style="captionSubtle" hint-align="left">$($update.name.replace(',',''))</text>`n
"@

$GroupedDeadlinedUpdates = $GroupedDeadlinedUpdates + $GroupedUpdate
}
}Else{
$GroupedDeadlinedUpdates = ''
}

IF($AvailableUpdates){
$GroupedAvailableUpdates = '<text hint-style="base" hint-align="left">' + $UpdatesAvailText + ' Available' + '</text>`n'
Foreach($Update in $AvailableUpdates[0..2]){
$GroupedUpdate = @"
<text hint-style="captionSubtle" hint-align="left">$($update.name.replace(',',''))</text>`n
"@

$GroupedAvailableUpdates = $GroupedAvailableUpdates + $GroupedUpdate
}
}Else{
$GroupedAvailableUpdates = ''
}

# Create an image file from base64 string and save to user temp location
If ($Base64LogoImage) {
    $LogoImage = "$env:TEMP\ToastLogo.png"
    [byte[]]$Bytes = [convert]::FromBase64String($Base64LogoImage)
    [System.IO.File]::WriteAllBytes($LogoImage, $Bytes)
}

IF($Base64InlineImage) {
    $InlineImage = "$env:TEMP\ToastInline.png"
    [byte[]]$Bytes = [convert]::FromBase64String($Base64InlineImage)
    [System.IO.File]::WriteAllBytes($InlineImage, $Bytes)
}
 
# Load some required namespaces
$null = [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]
$null = [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime]

# Register the AppID in the registry for use with the Action Center, if required
$RegPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings"
$App = "Microsoft.SoftwareCenter.DesktopToasts"
# Create registry entries if they don't exist
if (-NOT(Test-Path -Path "$RegPath\$App")) {
    New-Item -Path "$RegPath\$App" -Force
    New-ItemProperty -Path "$RegPath\$App" -Name "ShowInActionCenter" -Value 1 -PropertyType "DWORD" -Force
    New-ItemProperty -Path "$RegPath\$App" -Name "Enabled" -Value 1 -PropertyType "DWORD" -Force
}
# Make sure the app used with the action center is enabled
if ((Get-ItemProperty -Path "$RegPath\$App" -Name "Enabled").Enabled -ne "1")  {
    New-ItemProperty -Path "$RegPath\$App" -Name "Enabled" -Value 1 -PropertyType "DWORD" -Force
}

# Define the toast notification in XML format
[xml]$ToastTemplate = @"
<toast scenario="reminder">
    <visual>
    <binding template="ToastGeneric">
        <image placement="appLogoOverride" hint-crop="circle" src="$LogoImage" />
        <image src="$InlineImage" />
        <text>$Title</text>
        <text placement="attribution">from $ITdept</text>
        <group>
            <subgroup>
                $GroupedAvailableUpdates
                $GroupedDeadlinedUpdates
            </subgroup>
        </group>
        $Deadline
    </binding>
    </visual>
    <actions>
      <action content="View updates" activationType="protocol" arguments="$SoftwareCenterShortcut" />
      <action content="Dismiss" activationType="system" arguments="dismiss"/>
    </actions>
    <audio src="$AudioSource"/>
</toast>
"@

# Load the notification into the required format
$ToastXml = New-Object -TypeName Windows.Data.Xml.Dom.XmlDocument
$ToastXml.LoadXml($ToastTemplate.OuterXml)


# Clear old instances of this notification to prevent action center spam
[Windows.UI.Notifications.ToastNotificationManager]::History.Clear($app)

# Display
[Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($app).Show($ToastXml)
