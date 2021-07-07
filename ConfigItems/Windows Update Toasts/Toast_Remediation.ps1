## Displays a Windows 10 Toast Notification for Windows Updates
## SCCM Configuration Item Remediation Script

## References
# Source Script/Idea: https://smsagent.wordpress.com/2018/06/15/using-windows-10-toast-notifications-with-configmgr-application-deployments/
# Options for audio: https://docs.microsoft.com/en-us/uwp/schemas/tiles/toastschema/element-audio#attributes-and-elements
# Toast content schema: https://docs.microsoft.com/en-us/windows/uwp/design/shell/tiles-and-notifications/toast-schema
#
# Author: Colin Wilkins @SysBehr
# Assistance from @jgkps on the Windows Admins Discord 
# Modified: 03/13/2020
# Version: 3.8

# Required parameters
$Title = "Updates are ready to install"
$ITdept = "SysBehr Information Technology"
$SoftwarecenterShortcut = "softwarecenter:page=updates"
$AudioSource = "ms-winsoundevent:Notification.Default"

$LightTheme = (Get-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize -Name SystemUsesLightTheme).SystemUsesLightTheme

# Light theme should use dark logo files, Dark theme should use light logo files
IF($LightTheme){
# Base64 strings for populating toast images. Logo should be 48x48, Inline image (ex: IT/Company Logo) should be around 364(or longer)x100 to not display obnoxiously
$Base64LogoImage = "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"
#InlineImage is optional but looks real nice when you use a company logo
$Base64InlineImage = ""
}Else{
# Base64 strings for populating toast images. Logo should be 48x48, Inline image (ex: IT/Company Logo) should be around 364(or longer)x100 to not display obnoxiously
$Base64LogoImage = "iVBORw0KGgoAAAANSUhEUgAAADAAAAAwCAYAAABXAvmHAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAANySURBVGhD7Zg7aBRBGMfjK0qMeia+UgjRQstDMDYSQcSAgmhUEFGDhYhgk1LSaGFAwUIkoIXBgBqC0cqIGCsftY0GQQVRERQt4gOMqHf+/ptvjtO7i5fduYsL+4Mfc/fN7jczu7OvqUlISEjwTjabnY1rcZqFqocaxcXYgptwM67DZVhWh9juOIqtFqosNFSH+/AavsdSqO46HsB6270A6s6i2G+hykADDXgSR9Wa8QNHcAj78QrexMeouoBMJvOZ4gwusXQ5iFV2ACTWNOmgEx/VCuVXil5sw7m2WQHU6UxtwT78htr3E8VRnG6bVXYAJFUndFTFd+zGRqsuG/ZZiufwJ4pbmLK6ygyAhCmO2ANlpnxEsdqqQkMO3W2eW84nFLrY/Q+AZDryD4O02ewNnGNVkSFXCu8psQ3ivH6DnwGQSHP+apByvPMzrMob5NQBuq8GGMRLleBtAB3KZtMm0pFn/1o8hReLeJk2vlA6og+AJA0k1d1GF6yPOb8Ky8XLAHSfF90Wigy51uOOCdQZ34nLbZdwkEDzcpQzoPv8pG+VUw6d1uuB6LVQvKDjercRbRaKD3Rat069fOn9peTrwX8LndYrsRixULyg43qfF0MWihd0XB8jot9CVYe2O/EdNluofNhpJbfPN5SHLVR1aH+Q9kWrheIFAxi2AaQtFC8YwAsbwHwLxQc6rVfsX/jKQvGCjm9H0WeheEHHtSAg2i0UH+h0E45xDXygrLVwOEjQjHvwEO6ewA22S2TI5b6JuywUHpIcHM9VFitst9CQI41aqXiL8ywcHpLkBsAp1WLUJbxQxBMY6VuZ/etp4yml2GXhaJAoGACJ3Ye2PrzrrNob5JxFG7eDFjggFo4OydwZ6KEBLXkILYEstE0iQy4dedf5uxjtws2HZG4AWsfUopPWOHVG9JRssc1CQ440udy0Ueejz/t8SJgbgP3XE1KLtUJPyh5sCjaeBOzjVuDc0qKuI39H3kHSPwYg+K2vtSPoVqW15KKFr21Y8ghStwD1hNW2Yyh0t/FzwRaD5AUDcBBbhKcxf3ldZ+UZ0+IO5QDlIA7blFNdAP/1kOpCv1Pmb2ig5AAc1Gn5ZS8OoI5oUej0awotrbej/+lSDBrStBDHLPRP2LYR1+BGbEU9nKbmlZiGNd/VgZkWSkhISPBFTc1vc9xaMWyYdnsAAAAASUVORK5CYII="
#InlineImage is optional but looks real nice when you use a company logo
$Base64InlineImage = ""
}

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
