############################ Skip to line 112 for the meat and potatoes ############################
### This is pieced together from Cody Mathis' PSCCMClient module: https://github.com/CodyMathis123/PSCCMClient

enum Severity {
    None
    Informational
    Warning
    Error
}

enum CMLogType {
    FullCMTrace
    SimpleCMTrace
}

class CMLogEntry {
    [string]$Message
    [Severity]$Type
    [string]$Component
    [int]$Thread
    [datetime]$Timestamp
    hidden [string]$Offset

    CMLogEntry() {
    }

    CMLogEntry([string]$Message, [Severity]$Type, [string]$Component, [int]$Thread) {
        $this.Message = $Message
        $this.Type = $Type
        $this.Component = $Component
        $this.Thread = $Thread
    }

    [void]ResolveTimestamp([array]$LogLineSubArray, [CMLogType]$Type) {
        [string]$DateString = [string]::Empty
        [string]$TimeString = [string]::Empty
        [string]$TimeStringRaw = [string]::Empty

        try {
            switch ($Type) {
                FullCMTrace {
                    $DateString = $LogLineSubArray[3]
                    $TimeStringRaw = $LogLineSubArray[1]
                    $TimeString = $TimeStringRaw.Substring(0, 12)
                }
                SimpleCMTrace {
                    $DateTimeString = $LogLineSubArray[1]
                    $DateTimeStringArray = $DateTimeString.Split([char]32, [System.StringSplitOptions]::RemoveEmptyEntries)
                    $DateString = $DateTimeStringArray[0]
                    $TimeStringRaw = $DateTimeStringArray[1]
                    $TimeString = $TimeStringRaw.Substring(0, 12)
                }
            }
        }
        catch {
            if ($null -eq $DateString) {
                Write-Warning "Failed to split DateString [LogLineSubArray: $LogLineSubArray] [Error: $($_.Exception.Message)]"
            }
            elseif ($null -eq $TimeString) {
                Write-Warning "Failed to split TimeString [LogLineSubArray: $LogLineSubArray] [Error: $($_.Exception.Message)]"
            }
        }
        $DateStringArray = $DateString.Split([char]45)

        $MonthParser = $DateStringArray[0] -replace '\d', 'M'
        $DayParser = $DateStringArray[1] -replace '\d', 'd'

        $DateTimeFormat = [string]::Format('{0}-{1}-yyyyHH:mm:ss.fff', $MonthParser, $DayParser)
        $DateTimeString = [string]::Format('{0}{1}', $DateString, $TimeString)
        try {
            $This.Timestamp = [datetime]::ParseExact($DateTimeString, $DateTimeFormat, $null)
            # try{
                $this.Offset = $TimeStringRaw.Substring(12, 4)
            # }
            # catch {
                # $this.Offset = "+000"
            # }
        }
        catch {
            Write-Warning "Failed to parse [DateString: $DateString] [TimeString: $TimeString] with [Parser: $DateTimeFormat] [Error: $($_.Exception.Message)]"
        }
    }

    [bool]TestTimestampFilter([datetime]$TimestampGreaterThan, [datetime]$TimestampLessThan) {
        return $this.Timestamp -ge $TimestampGreaterThan -and $this.Timestamp -le $TimestampLessThan 
    }

    [string]ConvertToCMLogLine() {
        return [string]::Format('<![LOG[{0}]LOG]!><time="{1}{2}" date="{3}" component="{4}" context="" type="{5}" thread="{6}" file="">'
            , $this.Message
            , $this.Timestamp.ToString('HH:mm:ss.fffzz')
            , $this.Offset
            , $this.Timestamp.ToString('MM-dd-yyyy')
            , $this.Component
            , [int]$this.Type
            , $this.Thread)
    }
}

function ConvertTo-CCMLogFile {
    param(
        [CMLogEntry[]]$CMLogEntries,
        [string]$LogPath
    )
    $LogContent = foreach ($Entry in ($CMLogEntries | Sort-Object -Property Timestamp)) {
        $Entry.ConvertToCMLogLine()
    }

    Set-Content -Path $LogPath -Value $LogContent -Force
}
#########################################################################################

# Create our Diagnostic Collection Folders
IF(!(Test-Path C:\Windows\CCM\Logs\AutopilotDiagnostics)){
    New-Item -ItemType Directory -Path C:\Windows\CCM\Logs\AutopilotDiagnostics
}
IF(!(Test-Path C:\Windows\CCM\Logs\AutopilotDiagnostics\IntuneManagementExtension)){
    New-Item -ItemType Directory -Path C:\Windows\CCM\Logs\AutopilotDiagnostics\IntuneManagementExtension
}

# Define registry paths
$provisioningPath =  "registry::HKEY_LOCAL_MACHINE\software\microsoft\provisioning\*"
$autopilotDiagPath1 = "registry::HKEY_LOCAL_MACHINE\software\microsoft\provisioning\Diagnostics\Autopilot"
$autopilotDiagPath2 = "registry::HKEY_LOCAL_MACHINE\software\microsoft\provisioning\Diagnostics\Autopilot\*"
$omadmPath = "registry::HKEY_LOCAL_MACHINE\software\microsoft\provisioning\OMADM\*"
$esppath = "registry::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\Autopilot\EnrollmentStatusTracking\ESPTrackingInfo\Diagnostics"
$msiPath = "registry::HKEY_LOCAL_MACHINE\Software\Microsoft\EnterpriseDesktopAppManagement"
$officePath = "registry::HKEY_LOCAL_MACHINE\Software\Microsoft\OfficeCSP\*"
$sidecarPath = "registry::HKEY_LOCAL_MACHINE\Software\Microsoft\IntuneManagementExtension\Win32Apps\*"
$enrollmentsPath =  "registry::HKEY_LOCAL_MACHINE\Software\Microsoft\enrollments\*"

# Get registry info
$ProvisioningValues = Get-ItemProperty $provisioningPath
$APDiagnosticvalues1 = Get-ItemProperty $autopilotDiagPath1
$APDiagnosticvalues2 = Get-ItemProperty $autopilotDiagPath2
$OMADMValues = Get-ItemProperty $omadmPath
$ESPValues = Get-ItemProperty $esppath -ErrorAction SilentlyContinue
$msiValues = Get-ItemProperty $msiPath -ErrorAction SilentlyContinue
$OfficeValues = Get-ItemProperty $officePath
$SidecarValues = Get-ItemProperty $sidecarPath
$EnrollmentsValues = Get-ItemProperty $enrollmentsPath

$RegistryInfo = @($ProvisioningValues, $APDiagnosticvalues1, $APDiagnosticvalues2, $OMADMValues, $ESPValues, $msiValues, $OfficeValues, $SidecarValues, $EnrollmentsValues)

$PropsToExclude = @('PSChildName', 'PSParentPath', 'PSPath', 'PSProvider')

# Convert reg key entries to CCMLog entries
$ConvertedLog = Foreach ( $RegKey in ($RegistryInfo)) {
    foreach($RegValue in $RegKey){
        $ValueProps = ($RegValue | Get-Member -MemberType NoteProperty).Name
    
        $LogContent = foreach ($property in $ValueProps) {
            if ($property -notin $PropsToExclude) {
                [string]::Concat($property, " : ", $($RegValue.$property), [System.Environment]::NewLine)
            }
        }
        [CMLogEntry]::new($logcontent, [severity]::Informational, $RegValue.PSPath.Replace('Microsoft.PowerShell.Core\Registry::', ''), 0)
    }
}
ConvertTo-CCMLogFile -CMLogEntries $ConvertedLog -LogPath "C:\Windows\CCM\Logs\AutopilotDiagnostics\AutopilotRegistryKeys.log"

# Collect Intune Management Extension Logs
Copy-Item C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\* C:\Windows\CCM\Logs\AutopilotDiagnostics\IntuneManagementExtension -ErrorAction SilentlyContinue

$EventLogs = @(
'microsoft-windows-moderndeployment-diagnostics-provider'
'microsoft-windows-devicemanagement-enterprise-diagnostics-provider'
'microsoft-windows-aad'
'microsoft-windows-shell-core'
'microsoft-windows-user device registration'
)

Foreach($EventLog in $EventLogs){

    $TestPass = Try{ Get-WinEvent -ProviderName "$EventLog" -MaxEvents 1 -ErrorAction Stop } Catch { $null}

    IF($TestPass){
        $ConvertedLog = (Get-WinEvent -ProviderName "$EventLog") | select TimeCreated,ID,OpcodeDisplayName,Message | foreach { $E = [cmlogentry]::new($_.Message, [severity]::Informational, $_.OpcodeDisplayName, 1);$E.Timestamp = Get-Date $_.timecreated;Write-Output $e}
        ConvertTo-CCMLogFile -CMLogEntries $ConvertedLog -LogPath "C:\Windows\ccm\logs\AutopilotDiagnostics\$EventLog.log"
    }
}
