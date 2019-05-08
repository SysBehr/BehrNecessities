param (
[Parameter(Mandatory=$True)]
    [string]$TSName,
    [string]$LearnMoreLink,
    [switch]$AllowDefer,
    [datetime]$DeferDate,  
    [switch]$DontMinimize, 
    [int]$FreeSpaceThreshold = 15,
    [switch]$SkipDismClean,
    [switch]$SkipWindowsTempClean,
    [switch]$SkipUserTempClean,
    [switch]$NoShortcut,
    [switch]$ToastNotifications,
    [string]$LogPath = "$Env:UserProfile\ServicingDebug.log",
    [switch]$Silent
)


function Get-XamlObject
{
<#
	.NOTES FOR Get-XamlObject
	===========================================================================
	 Created on:   	27/01/2017
	 Created by:   	Jim Moyle
	 GitHub link: 	https://github.com/JimMoyle/GUIDemo
	 Twitter: 		@JimMoyle
	===========================================================================
#>
	[CmdletBinding()]
	param (
		[Parameter(Position = 0,
				   Mandatory = $true,
				   ValuefromPipelineByPropertyName = $true,
				   ValuefromPipeline = $true)]
		[Alias("FullName")]
		[System.String[]]$Path
	)

	BEGIN
	{
		Set-StrictMode -Version Latest

		$wpfObjects = @{ }
		Add-Type -AssemblyName presentationframework, presentationcore

	} #BEGIN

	PROCESS
	{
		try
		{
			foreach ($xamlFile in $Path)
			{
				#Change content of Xaml file to be a set of powershell GUI objects
				$inputXML = Get-Content -Path $xamlFile -ErrorAction Stop
				$inputXMLClean = $inputXML -replace 'mc:Ignorable="d"', '' -replace "x:N", 'N' -replace 'x:Class=".*?"', '' -replace 'd:DesignHeight="\d*?"', '' -replace 'd:DesignWidth="\d*?"', ''
				[xml]$xaml = $inputXMLClean
				$reader = New-Object System.Xml.XmlNodeReader $xaml -ErrorAction Stop
				$tempform = [Windows.Markup.XamlReader]::Load($reader)

				#Grab named objects from tree and put in a flat structure
				$namedNodes = $xaml.SelectNodes("//*[@*[contains(translate(name(.),'n','N'),'Name')]]")
				$namedNodes | ForEach-Object {

					$wpfObjects.Add($_.Name, $tempform.FindName($_.Name))

				} #foreach-object
			} #foreach xamlpath
		} #try
		catch
		{
			throw $error[0]
		} #catch
	} #PROCESS

	END
	{
		Write-Output $wpfObjects
	} #END
}

#region
$wpf = [hashtable]::Synchronized(@{ })
$wpf = Get-ChildItem -Path $PSScriptRoot -Filter *.xaml -file | Where-Object { $_.Name -ne 'App.xaml' } | Get-XamlObject
$wpf.Win10Servicingframe.NavigationService.Navigate($wpf.WelcomePage) | Out-Null
$iconsrc = New-Object System.Windows.Controls.Image

$bgsrc = New-Object System.Uri("$PSScriptRoot\background.png") ##Customize the main window Background (must be 350px x 525px)
$wpf.WindowsServicingGUI.Title = "Windows 10 Servicing" ##Customize the main window Title
$iconsrc.Source = "$PSScriptRoot\icon.ico" ##Customize the main window Icon

##Customize the InfoTextBlocks on the welcome page
$wpf.InfoTextBlock1.FontFamily = "Segoe UI"
$wpf.InfoTextBlock1.FontSize = 12
$wpf.InfoTextBlock1.Text = "This upgrade may take a while so please make sure you have saved your work and have ample time for it to complete."
$wpf.InfoTextBlock2.FontFamily = "Segoe UI"
$wpf.InfoTextBlock2.FontSize = 12
$wpf.InfoTextBlock2.Text = "We recommend enabling OneDrive AutoSave for your local documents."

## Do some stuff
$bgimg = New-Object System.Windows.Media.Imaging.BitmapImage $bgsrc
$bgbrush = New-Object System.Windows.Media.ImageBrush $bgimg
$wpf.WindowsServicingGUI.Background = $bgbrush
$wpf.WindowsServicingGUI.Icon = $iconsrc.Source
$wpf.TSLabel.Content = $TSName

$wpf.AllowDefer = $AllowDefer
$wpf.DeferDate = $DeferDate
$wpf.FreeSpaceThreshold = $FreeSpaceThreshold  
$wpf.SkipDismClean = $SkipDismClean
$wpf.SkipWindowsTempClean = $SkipWindowsTempClean
$wpf.SkipUserTempClean = $SkipUserTempClean
$wpf.path = $PSScriptRoot
$wpf.LogPath = $LogPath

#Log Entries
"Beginning execution: $(Get-Date -Format 'MM/dd/yy hh:mm:ss')" | Out-File $wpf.LogPath
"Executing from: $PSScriptRoot" | Out-File $wpf.LogPath -Append

## Set Learn more link to the parameter
IF($LearnMoreLink){
$wpf.hyperlink.add_Click({
Start-Process $LearnMoreLink
})
}Else{
$wpf.learnlink.Opacity = 0
$wpf.learnlink.IsEnabled = $false
}

$script:initfreespace = [Math]::Round((GWMI win32_logicaldisk | Where-Object {$_.DeviceID -eq 'C:'}).Freespace / 1GB)
$wpf.freediskspace.Content = "$script:initfreespace GB"

        ## Create an empty string array for TS reference packages
        $wpf.TSReferencePackageIDs = @()
        
        ## Get the Software Center
        $wpf.softwareCenter = New-Object -ComObject "UIResource.UIResourceMgr"

        IF($wpf.softwareCenter){

            ## Get the Task Sequence object
            $wpf.taskSequence = $wpf.softwareCenter.GetAvailableApplications() | Where { $_.PackageName -eq "$TSName" }
        
            ## Populate some variables
            IF($wpf.taskSequence){
                $wpf.taskSequenceProgramID = $wpf.taskSequence.ID
                $wpf.taskSequencePackageID = $wpf.taskSequence.PackageID

                ## Fill the array with PackageIDs of referenced packages
                Foreach($i in $wpf.taskSequence.GetMemberPrograms()){
                    $wpf.TSReferencePackageIDs += $i.PackageID
                }
            }
        }

if(!$DontMinimize){
## Minimize Windows
[__comobject]$ShellApp = New-Object -ComObject 'Shell.Application' -ErrorAction 'SilentlyContinue'
$ShellApp.MinimizeAll()

## Unminimize if deferred
$wpf.laterButton.add_click({

    IF(!(Test-Path "$env:PUBLIC\Desktop\Resume Windows 10 Upgrade.url") -or !($NoShortcut)){
        Copy-Item "$PSSCriptRoot\Resume Windows 10 Upgrade.url" "$env:PUBLIC\Desktop" -Force
    }

    IF($ToastNotifications -and !(Get-ScheduledTask -TaskName "Win10ServicingToastNotify" -ErrorAction SilentlyContinue)){
    $execute = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
    $argument = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File " + '"' + "$PSSCriptRoot\ToastReminder.ps1" + '"' + " -TSName " + '"' + $TSName + '"'
    $action = New-ScheduledTaskAction -Execute $execute -Argument $argument
    $triggers= @()
    $trigger1 = New-ScheduledTaskTrigger -AtLogOn
    #$trigger2= New-ScheduledTaskTrigger -Daily -At 1:45pm
    $triggers += $trigger1
    #$triggers += $trigger2
    Register-ScheduledTask -Action $action -Trigger $triggers -TaskName "Win10ServicingToastNotify" -Description "User Reminder for Windows 10 Upgrade availability"
    }

    "Upgrade Deferred by User $Env:USERNAME at: $(Get-Date -Format 'MM/dd/yy hh:mm:ss')" | Out-File $wpf.LogPath -Append
    Start-Sleep -Milliseconds 500
    [__comobject]$ShellApp = New-Object -ComObject 'Shell.Application' -ErrorAction 'SilentlyContinue'
    $ShellApp.UndoMinimizeALL()
})
}

IF($script:initfreespace -le $FreeSpaceThreshold){
$wpf.freediskspace.Foreground = 'Orange'
$wpf.diskspacemessage.Content = "Looks like we need to clear some disk space. We will perform`nthese operations automatically."

$wpf.upgradeButton.add_Click({
    $wpf.Win10Servicingframe.NavigationService.Navigate($wpf.GettingReady)
  
    $runspace = [runspacefactory]::CreateRunspace()
    $powershell = [powershell]::Create()
    $powershell.runspace = $runspace
    $runspace.Open()
    $runspace.SessionStateProxy.SetVariable("wpf",$wpf)

    [void]$powershell.AddScript({
    Start-Sleep -Seconds 4
    $wpf.Win10Servicingframe.Dispatcher.Invoke([action]{
            $wpf.Win10Servicingframe.NavigationService.Navigate($wpf.DiskClear)
        })
    })

    ## Clean CCMCache
    [void]$powershell.AddScript({
    "Executing CCMCache Cleanup..." | Out-File $wpf.LogPath -Append
    ## Get Cache Elements
    $wpf.CMObject = New-Object -ComObject "UIResource.UIResourceMGR"
    $wpf.CMCacheObject = $wpf.CMObject.GetCacheInfo()
    $wpf.CMCacheElementObject = $wpf.CMCacheObject.GetCacheElements()
    
    "CMCacheElementObject Count: $($wpf.CMCacheElementObject.count)" | Out-File $wpf.LogPath -Append
    IF($wpf.CMCacheElementObject.Count -ge ($wpf.TSReferencePackageIDs.Count + 1)){
            Foreach ($j in $wpf.CMCacheElementObject){
                IF(($j.Location -ne $wpf.path) -and ($j.ContentID -notin $wpf.TSReferencePackageIDs)){
                    $wpf.CMCacheObject.DeleteCacheElement($j.CacheElementID)
                    "Deleting Cache Object: $($j.ContentID)" | Out-File $wpf.LogPath -Append
                }
            }
    }
    #>
    Start-Sleep -Seconds 5
    })

    ## Clean User Temp
    [void]$powershell.AddScript({
    IF(!$wpf.SkipUserTempClean){
    "Executing User Temp Cleanup..." | Out-File $wpf.LogPath -Append
    Start-Sleep -Seconds 5
    #Get-ChildItem "C:\users\*\AppData\Local\Temp\*" -Force -ErrorAction SilentlyContinue | remove-item -force -Verbose -recurse -ErrorAction SilentlyContinue
    #| Where-Object { ($_.CreationTime -lt $(Get-Date).AddDays(-2))}
    }
    })

    ## Clean Windows Temp
    [void]$powershell.AddScript({

    IF(!$wpf.SkipWindowsTempClean){
    "Executing Windows Temp Cleanup..." | Out-File $wpf.LogPath -Append
    Start-Sleep -Seconds 5
    #Get-ChildItem "C:\Windows\Temp\*" -Force -Verbose -ErrorAction SilentlyContinue | remove-item -force -Verbose -recurse -ErrorAction SilentlyContinue
    #| Where-Object { ($_.CreationTime -lt $(Get-Date).AddDays(-2)) }
    }
    })
    
    ## Dism Cleanup (ResetBase)
    [void]$powershell.AddScript({
    IF(!$wpf.SkipDismClean){
    "Executing DISM Cleanup..." | Out-File $wpf.LogPath -Append
    Start-Sleep -Seconds 5
    #Start-Process -FilePath "C:\Windows\System32\Dism.exe" -ArgumentList "/online /Cleanup-Image /StartComponentCleanup /ResetBase" -Wait
    }
    })
    [void]$powershell.AddScript({
    $wpf.clearStatus.Dispatcher.Invoke([action]{
    $wpf.ClearingDiskTextBlock.Text = ""
    $wpf.clearStatus.Content = "Done."
    $wpf.clearstatusBar.IsIndeterminate = $false
    $wpf.clearStatusBar.Value = 100
    })
    })

    [void]$powershell.AddScript({
        Start-Sleep -Seconds 3
        $wpf.Win10Servicingframe.Dispatcher.Invoke([action]{
        $wpf.Win10Servicingframe.NavigationService.Navigate($wpf.Ready)
        })
    })

    [void]$powershell.AddScript({

    IF(Test-Path "C:\Users\Public\Desktop\Resume Windows 10 Upgrade.url"){
    Remove-Item "C:\Users\Public\Desktop\Resume Windows 10 Upgrade.url" -Force
    }
    $toasty = Get-ScheduledTask -TaskName "Win10ServicingToastNotify" -ErrorAction SilentlyContinue
    IF($toasty){
    $toasty | Unregister-ScheduledTask -Confirm:$false
    }

        Start-Sleep -Seconds 3
        "Executing Task Sequence: $($wpf.taskSequence.FullName) | $($wpf.taskSequencePackageID)" | Out-File $wpf.LogPath -Append
        $wpf.softwareCenter.ExecuteProgram($wpf.taskSequenceProgramID,$wpf.taskSequencePackageID,$true)
        $wpf.WindowsServicingGUI.Dispatcher.Invoke([action]{
        $wpf.WindowsServicingGUI.Close()
        })
    })

    $asyncObject = $powershell.BeginInvoke()
})

}Else{
    $wpf.freediskspace.Foreground = 'Lime'
    $wpf.diskspacemessage.Content = "We're good to go! Please wait..."

    $wpf.upgradeButton.add_Click({
        $wpf.Win10Servicingframe.NavigationService.Navigate($wpf.GettingReady)
  
        $runspace = [runspacefactory]::CreateRunspace()
        $powershell = [powershell]::Create()
        $powershell.runspace = $runspace
        $runspace.Open()
        $runspace.SessionStateProxy.SetVariable("wpf",$wpf)

        [void]$powershell.AddScript({
        ## Clean CCMCache
        "Executing CCMCache Cleanup..." | Out-File $wpf.LogPath -Append
        ## Get Cache Elements
        $wpf.CMObject = New-Object -ComObject "UIResource.UIResourceMGR"
        $wpf.CMCacheObject = $wpf.CMObject.GetCacheInfo()
        $wpf.CMCacheElementObject = $wpf.CMCacheObject.GetCacheElements()
    
        "CMCacheElementObject Count: $($wpf.CMCacheElementObject.count)" | Out-File $wpf.LogPath -Append
        IF($wpf.CMCacheElementObject.Count -ge ($wpf.TSReferencePackageIDs.Count + 1)){
                Foreach ($j in $wpf.CMCacheElementObject){
                    IF(($j.Location -ne $wpf.path) -and ($j.ContentID -notin $wpf.TSReferencePackageIDs)){
                        $wpf.CMCacheObject.DeleteCacheElement($j.CacheElementID)
                        "Deleting Cache Object: $($j.ContentID)" | Out-File $wpf.LogPath -Append
                    }
                }
        }
        Start-Sleep -Seconds 3

        $wpf.Win10Servicingframe.Dispatcher.Invoke([action]{
            $wpf.Win10Servicingframe.NavigationService.Navigate($wpf.Ready)
        })

        IF(Test-Path "C:\Users\Public\Desktop\Resume Windows 10 Upgrade.url"){
        Remove-Item "C:\Users\Public\Desktop\Resume Windows 10 Upgrade.url" -Force
        }
        $toasty = Get-ScheduledTask -TaskName "Win10ServicingToastNotify" -ErrorAction SilentlyContinue
        IF($toasty){
        $toasty | Unregister-ScheduledTask -Confirm:$false
        }

        "Executing Task Sequence: $($wpf.taskSequence.FullName) | $($wpf.taskSequencePackageID)" | Out-File $wpf.LogPath -Append
        $wpf.softwareCenter.ExecuteProgram($wpf.taskSequenceProgramID,$wpf.taskSequencePackageID,$true)
        Start-Sleep -Seconds 2
        $wpf.WindowsServicingGUI.Dispatcher.Invoke([action]{
        $wpf.WindowsServicingGUI.Close()
        })
    })
    $asyncObject = $powershell.BeginInvoke()
})
}

IF(!$Silent){
$wpf.WindowsServicingGUI.showDialog() | Out-Null
}ELSE{

$TSReferencePackageIDs = @()
$softwareCenter = New-Object -ComObject "UIResource.UIResourceMgr"
$taskSequence = $softwareCenter.GetAvailableApplications() | Where { $_.PackageName -eq "$TSName" }
        
## Populate some variables
IF($taskSequence){
    $taskSequenceProgramID = $taskSequence.ID
    $taskSequencePackageID = $taskSequence.PackageID

    ## Fill the array with PackageIDs of referenced packages
    Foreach($i in $taskSequence.GetMemberPrograms()){
        $TSReferencePackageIDs+=$i.PackageID
    }

}

## Get Cache Elements
$CMObject = New-Object -ComObject "UIResource.UIResourceMGR"
$CMCacheObject = $CMObject.GetCacheInfo()
$CMCacheElementObject = $CMCacheObject.GetCacheElements()
        
IF($CMCacheElementObject.Count -ge ($TSReferencePackageIDs.Count + 1)){
        Foreach ($i in $CMCacheElementObject){
            IF(($i.Location -ne $PSScriptRoot) -and ($i.ContentID -notin $TSReferencePackageIDs)){
                $CMCacheObject.DeleteCacheElement($i.CacheElementID)
            }
        }
    $softwareCenter.ExecuteProgram($taskSequenceProgramID,$taskSequencePackageID,$true)
}
}
