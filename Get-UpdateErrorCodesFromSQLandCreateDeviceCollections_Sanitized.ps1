#
# Press 'F5' to run this script. Running this script will load the ConfigurationManager
# module for Windows PowerShell and will connect to the site.
#
# This script was auto-generated at '2/27/2020 1:20:06 PM'.

# Uncomment the line below if running in an environment where script signing is 
# required.
#Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process

# Site configuration
$SiteCode = "ABC" # Site code 
$ProviderMachineName = "sccm-01.contoso.local" # SMS Provider machine name

# Collection creation - change to $true for device collection generation
$CreateCollections = $false

############################## REQUIRES POWERSHELL SQL MODULE##################################
#Install-module SQLServer

# Customizations
$initParams = @{}
#$initParams.Add("Verbose", $true) # Uncomment this line to enable verbose logging
#$initParams.Add("ErrorAction", "Stop") # Uncomment this line to stop the script on any errors

# Do not change anything below this line

# Import the ConfigurationManager.psd1 module 
if((Get-Module ConfigurationManager) -eq $null) {
    Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1" @initParams 
}

# Connect to the site's drive if it is not already present
if((Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue) -eq $null) {
    New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $ProviderMachineName @initParams
}

# Function for CMErrorMessage Translation

function Get-CMErrorMessage {
[CmdletBinding()]
    param
        (
        [Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
            [int64]$ErrorCode
        )
 
    [void][System.Reflection.Assembly]::LoadFrom("C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole\bin\SrsResources.dll")
    [SrsResources.Localization]::GetErrorMessage($ErrorCode,"en-US")
}

# Function to convert Error Codes

function Convert-ErrorCode {
[CmdletBinding()]
    param
        (
        [Parameter(Mandatory=$True,ParameterSetName='Decimal')]
            [int64]$DecimalErrorCode,
        [Parameter(Mandatory=$True,ParameterSetName='Hex')]
            $HexErrorCode
        )
    if ($DecimalErrorCode)
        {
            $hex = '{0:x}' -f $DecimalErrorCode
            $hex = "0x" + $hex
            $hex
        }
 
    if ($HexErrorCode)
        {
            $DecErrorCode = $HexErrorCode.ToString()
            $DecErrorCode
        }
}

$ErrorCodes = Invoke-Sqlcmd -ServerInstance $ProviderMachineName -Database "CM_$SiteCode" -Query "Select LastErrorCode from v_Update_ComplianceStatusReported where LastErrorCode is not NULL group by LastErrorCode"
Set-Location "$($SiteCode):\" @initParams

$Errortable = @()

Foreach($ErrorCode in $ErrorCodes){
    #$description = Get-CMErrorMessage -ErrorCode $Errorcode.LastErrorCode
    $description = Invoke-RestMethod -Method Get -Uri "https://asdlabfunctions.azurewebsites.net/api/geterrormessage?exitcode=$($ErrorCode.LastErrorCode)"
    $errorObject = New-Object psobject
    Add-Member -InputObject $errorObject -MemberType NoteProperty -Name DecErrorCode -Value $Errorcode.LastErrorCode
    # This nasty try/catch tries to convert the signed decimals into their unsigned counterparts... except for exit code 0
    Try{
    Add-Member -InputObject $errorObject -MemberType NoteProperty -Name UnsignedDecErrorcode -Value $([uint32](Convert-ErrorCode -DecimalErrorCode $ErrorCode.LastErrorCode).Replace('ffffffff',''))
    }Catch{
    Add-Member -InputObject $errorObject -MemberType NoteProperty -Name UnsignedDecErrorcode -Value 0
    }
    Add-Member -InputObject $errorObject -MemberType NoteProperty -Name Description -Value $description
    $Errortable += $errorObject

    IF($CreateCollections){
        IF(Get-CMDeviceCollection -Name "Update Error: $($ErrorCode.LastErrorCode)"){
            Write-Warning "A Collection for error code $($ErrorCode.LastErrorCode) already exists. Skipping..."
        }Else{
            $NewCollection = New-CMDeviceCollection -LimitingCollectionName "All Desktop and Server Clients" -Name "Update Error: $($ErrorCode.LastErrorCode)" -Comment $description -RefreshType Periodic
            Add-CMDeviceCollectionQueryMembershipRule -Collection $NewCollection -RuleName "$($ErrorCode.LastErrorCode)" -QueryExpression "Select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from sms_r_system inner join SMS_UpdateComplianceStatus on SMS_UpdateComplianceStatus.machineid=sms_r_system.resourceid where SMS_UpdateComplianceStatus.LastErrorCode = $($ErrorCode.LastErrorCode)"
            Write-Output "Created Collection Update Error: $($ErrorCode.LastErrorCode)."
        }
    }
}

$Errortable | Format-Table -AutoSize

## For Offline/No connection to SQL testing
$ErrorCodes = @()

Foreach($e in @(  -2147467259,
  -2147418113,
  -2147417848,
  -2147024894,
  -2147024784,
  -2147023436,
  -2147023293,
  -2147023278,
  -2147023261,
  -2147023254,
  -2147010798,
  -2146889721,
  -2145124341,
  -2145124322,
  -2145124318,
  -2145124303,
  -2145123272,
  -2145123262,
  -2145107940,
  -2145107924,
  -2145099774,
  -2016411062,
  -2016410860,
  -2016410032,
  -2016410031,
  -2016410012,
  -2016410008,
  -2016409966,
  -2016409958,
  -2016409957,
  -2016409844,
            0)){
            $i = New-Object psobject
            Add-Member -InputObject $i -MemberType NoteProperty -Name LastErrorCode -Value $e
            $ErrorCodes += $i
            }