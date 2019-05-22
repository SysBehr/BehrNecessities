<#
    [SetupConfig]
    Priority=High
    BitLocker=AlwaysSuspend
    Compat=IgnoreWarning
#>

Param(

    [string]
    $ActualValue, #SCCM passes in expected value as a parameter to this remediation script. This will catch it.

    [string]
    $iniFile = "$($env:SystemDrive)\Users\Default\AppData\Local\Microsoft\Windows\WSUS\SetupConfig.ini",

    [string]
    $iniHeader = "[SetupConfig]",

    [HashTable] #All items in the this table will be added to the INI.
    $Settings = @{
        "BitLocker"="AlwaysSuspend";
        "Compat"="IgnoreWarning";
        "Priority"="High"
    },

    <#
    #In your CI, you would use one of these per item being checked. 
    #So for your BitLocker check, just use the Bitlocker item below and comment out the above full table above.
    [HashTable]
    $Settings = @{
        "BitLocker"="AlwaysSuspend"
    },

    [HashTable]
    $Settings = @{
        "Compat"="IgnoreWarning"
    },

    [HashTable]
    $Settings = @{
        "Priority"="High"
    },
    #>

    [Switch]
    $Remove = $False
)

$iniSetupConfigContent = @()
$MatchingLines = @()
$OutPutArray = @()

Try {

    If(!(Test-Path -Path $iniFile -ErrorAction SilentlyContinue)) {
        $iniSetupConfigContent += $iniHeader
    }
    Else {
        $iniSetupConfigContent += (Get-Content $iniFile)
    }

    If($Settings) {
        ForEach($SettingName in $Settings.Keys)
        {
            $MatchingLines += $iniSetupConfigContent -like ("*$($SettingName)*")
        }

        ForEach ($Line in $iniSetupConfigContent)
        {
            If($Line -NotIn $MatchingLines -and $Line -ne "")
            {
                $OutPutArray += $Line
            }
        }

        If(!($Remove.IsPresent)) {
            ForEach($SettingName in $Settings.Keys)
            {
                $NewValue = "{0}={1}" -f $SettingName, $Settings[$SettingName]
                $OutPutArray += $NewValue
            }
        }
    }

    New-Item -Path $iniFile -ItemType File -Force | Out-Null
    $OutPutArray | Out-File -FilePath $iniFile -Force | Out-Null
    $iniSetupConfigContent = $null
    $OutPutArray = $null
}
Catch {
    Write-Output $Error[0]
}
