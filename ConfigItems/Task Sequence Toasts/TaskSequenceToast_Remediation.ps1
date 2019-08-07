## Displays a Windows 10 Toast Notification for Task Sequences
## SCCM Configuration Item Remediation Script

## References
# Source Script/Idea: https://smsagent.wordpress.com/2018/06/15/using-windows-10-toast-notifications-with-configmgr-application-deployments/
# Options for audio: https://docs.microsoft.com/en-us/uwp/schemas/tiles/toastschema/element-audio#attributes-and-elements
# Toast content schema: https://docs.microsoft.com/en-us/windows/uwp/design/shell/tiles-and-notifications/toast-schema
# Author: Colin Wilkins @sysBehr
# Modified: 08/06/2019
# Version: 1.2

# Required parameters
# |-- Customizable --|
$Title = "Windows 10 Feature Update"
$ITdept = "Your Company Information Technology"
$HelpLink = "https://isotropic.org/papers/chicken.pdf" # Optional - for Readme
$SoftwarecenterShortcut = "softwarecenter:page=OSD"
$AudioSource = "ms-winsoundevent:Notification.Default"
$ShowAvailable = $true
$ShowRequired = $true

# Base64 strings for populating toast images. Logo should be 48x48, Inline image (ex: IT/Company Logo) should be around 364(or longer)x100 to not display obnoxiously
$Base64LogoImage = "iVBORw0KGgoAAAANSUhEUgAAADAAAAAwCAYAAABXAvmHAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAANySURBVGhD7Zg7aBRBGMfjK0qMeia+UgjRQstDMDYSQcSAgmhUEFGDhYhgk1LSaGFAwUIkoIXBgBqC0cqIGCsftY0GQQVRERQt4gOMqHf+/ptvjtO7i5fduYsL+4Mfc/fN7jczu7OvqUlISEjwTjabnY1rcZqFqocaxcXYgptwM67DZVhWh9juOIqtFqosNFSH+/AavsdSqO46HsB6270A6s6i2G+hykADDXgSR9Wa8QNHcAj78QrexMeouoBMJvOZ4gwusXQ5iFV2ACTWNOmgEx/VCuVXil5sw7m2WQHU6UxtwT78htr3E8VRnG6bVXYAJFUndFTFd+zGRqsuG/ZZiufwJ4pbmLK6ygyAhCmO2ANlpnxEsdqqQkMO3W2eW84nFLrY/Q+AZDryD4O02ewNnGNVkSFXCu8psQ3ivH6DnwGQSHP+apByvPMzrMob5NQBuq8GGMRLleBtAB3KZtMm0pFn/1o8hReLeJk2vlA6og+AJA0k1d1GF6yPOb8Ky8XLAHSfF90Wigy51uOOCdQZ34nLbZdwkEDzcpQzoPv8pG+VUw6d1uuB6LVQvKDjercRbRaKD3Rat069fOn9peTrwX8LndYrsRixULyg43qfF0MWihd0XB8jot9CVYe2O/EdNluofNhpJbfPN5SHLVR1aH+Q9kWrheIFAxi2AaQtFC8YwAsbwHwLxQc6rVfsX/jKQvGCjm9H0WeheEHHtSAg2i0UH+h0E45xDXygrLVwOEjQjHvwEO6ewA22S2TI5b6JuywUHpIcHM9VFitst9CQI41aqXiL8ywcHpLkBsAp1WLUJbxQxBMY6VuZ/etp4yml2GXhaJAoGACJ3Ye2PrzrrNob5JxFG7eDFjggFo4OydwZ6KEBLXkILYEstE0iQy4dedf5uxjtws2HZG4AWsfUopPWOHVG9JRssc1CQ440udy0Ueejz/t8SJgbgP3XE1KLtUJPyh5sCjaeBOzjVuDc0qKuI39H3kHSPwYg+K2vtSPoVqW15KKFr21Y8ghStwD1hNW2Yyh0t/FzwRaD5AUDcBBbhKcxf3ldZ+UZ0+IO5QDlIA7blFNdAP/1kOpCv1Pmb2ig5AAc1Gn5ZS8OoI5oUej0awotrbej/+lSDBrStBDHLPRP2LYR1+BGbEU9nKbmlZiGNd/VgZkWSkhISPBFTc1vc9xaMWyYdnsAAAAASUVORK5CYII="
#InlineImage is optional but looks real nice when you use a company logo
$Base64InlineImage = ""

<#
#Use this to create a Base64 image string and copy it to the clipboard for pasting into the Base64 variables
$File = "C:\Tools\SCCM Scripts\Chicken.png"
$Image = [System.Drawing.Image]::FromFile($File)
$MemoryStream = New-Object System.IO.MemoryStream
$Image.Save($MemoryStream, $Image.RawFormat)
[System.Byte[]]$Bytes = $MemoryStream.ToArray()
$Base64 = [System.Convert]::ToBase64String($Bytes)
$Image.Dispose()
$MemoryStream.Dispose()
$Base64 | Set-Clipboard
#>

$softwareCenter = New-Object -ComObject "UIResource.UIResourceMgr"

IF($ShowAvailable){
$AvailableTSList = $Softwarecenter.GetAvailableApplications() | Where-Object {$_.IsAssigned -ne 1}
}Else{
$AvailableTSList = @()
}

IF($ShowRequired){
$RequiredTSList = $Softwarecenter.GetAvailableApplications() | Where-Object {$_.IsAssigned -eq 1}
}Else{
$RequiredTSList = @()
}

$DeadlineTSList = @()
Foreach($TaskSequence in $RequiredTSList){
$DeadlineTSList += Get-CimInstance -Query "SELECT * FROM CCM_Program WHERE PackageID='$($TaskSequence.PackageID)' AND ProgramID='*'" -Namespace "root\ccm\clientsdk"
}

IF($DeadlineTSList){
$Deadline = ($DeadlineTSList | Sort-Object -Property Deadline -Descending)[0].Deadline.ToUniversalTime()
$TimeSpan = ( $Deadline ) - (get-date)
}

IF($HelpLink){
$Actions = @"
<action content="Take Action" activationType="protocol" arguments="$SoftwareCenterShortcut"/>
<action content="More Info" activationType="protocol" arguments="$HelpLink"/>
<action content="Dismiss" activationType="system" arguments="dismiss"/>
"@
}Else{
$Actions = @"
<action content="Take Action" activationType="protocol" arguments="$SoftwareCenterShortcut"/>
<action content="Dismiss" activationType="system" arguments="dismiss"/>
"@
}

# Do nothing if we don't have Task Sequences (just in case)
IF(!$AvailableTSList -and !$RequiredTSList){
Return
}

switch ($AvailableTSList.Name.Count) {
    {$_ -gt 1} {$TSAvailText = "$($AvailableTSList.Name.Count) Actions"}
    {$_ -eq 1} {$TSAvailText = "$($AvailableTSList.Name.Count) Action"}
}

switch ($RequiredTSList.Name.Count) {
    {$_ -gt 1} {$TSReqText = "$($RequiredTSList.Name.Count) Actions"}
    {$_ -eq 1} {$TSReqText = "$($RequiredTSList.Name.Count) Action"}
}

# Set Deadline XML format
IF($TimeSpan -ne $null) {
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
}Else{
$Deadline = $null
}

# Do some things with the returned Required Task Sequences so they stack for the XML.
IF($RequiredTSList){
$GroupedRequiredTSList = '<text hint-style="base" hint-align="left">' + $TSReqText + ' Required' + '</text>`n'
Foreach($TS in $RequiredTSList){
$GroupedRequiredTS = @"
<text hint-style="captionSubtle" hint-align="left">$($TS.FullName)</text>`n
"@

$GroupedRequiredTSList = $GroupedRequiredTSList + $GroupedRequiredTS
}
}Else{
$GroupedRequiredTSList = ''
}

# Do some things with the returned Available Task Sequences so they stack for the XML.
IF($AvailableTSList){
$GroupedTSList = '<text hint-style="base" hint-align="left">' + $TSAvailText + ' Available' + '</text>`n'
Foreach($TS in $AvailableTSList){
$GroupedTS = @"
<text hint-style="captionSubtle" hint-align="left">$($TS.FullName)</text>`n
"@

$GroupedTSList = $GroupedTSList + $GroupedTS
}
}Else{
$GroupedTSList = ''
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
                $GroupedRequiredTSList
                $GroupedTSList
            </subgroup>
        </group>
        $Deadline
    </binding>
    </visual>
    <actions>
    $Actions
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
