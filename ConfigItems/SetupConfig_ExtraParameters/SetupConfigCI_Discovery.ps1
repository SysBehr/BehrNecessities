# Note: These should be created as separate settings for the CI - modify the remdiation script to replace as many parameters as you need to set/enforce.

Param(
    [string]
    $SettingName="BitLocker", #Change this for each line item you want to check for. BitLocker, Priority, Compat

    <#
    [string]
    $SettingName="Compat",

    [string]
    $SettingName="Priority", 
    #>

    [string]
    $iniFile = "$($env:SystemDrive)\Users\Default\AppData\Local\Microsoft\Windows\WSUS\SetupConfig.ini"
)

Try {
    If (Test-Path -Path $iniFile -ErrorAction Stop) {
        $Setupfile = (Get-Content $iniFile)
        [bool]$FoundMatch = $false
        ForEach ($line in $setupfile) {
            If ($line -like "$($SettingName)*") {
                [bool]$FoundMatch = $true
                Return $line.replace("$($SettingName)=", "")
            }
        }
        If (!($FoundMatch)) {
            Return "NonCompliant"
        }
    }
    Else {
            Return "NonCompliant"        
    }
}
Catch {
    Return "NonCompliant"
}
