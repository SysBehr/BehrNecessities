$CCMCache = Get-WmiObject -Namespace "ROOT\CCM\SoftMgmtAgent" -Class CacheConfig
$c = Gwmi Win32_Volume | Where {$_.Name -eq 'C:\'} | Select Capacity,FreeSpace

$TotalDiskSpace = [Math]::Round($c.Capacity/1GB,2)
$FreeDiskSpace = [Math]::Round($c.FreeSpace/1GB,2)

$TotalCacheSize = [Math]::Round($CCMCache.size/1000,2)
$UsedCacheSize = [Math]::Round(((Get-ChildItem $CCMCache.Location -Recurse -Force | Measure-Object -Property Length -Sum -ErrorAction Stop).Sum / 1GB),2)

$DiskFreePercent = [Math]::Round(($FreeDiskSpace/$TotalDiskSpace),2)*100
$CacheUsedPercent = [Math]::Round($UsedCacheSize/$TotalCacheSize,2)*100

$DesiredCacheSize = <# 10% of Disk #> ($TotalDiskSpace * .10) * 1000
$MinimumCacheSize = 5120

#If Desired Cache is greater than MB free on disk, set it to 50% of available FreeSPace
If($DesiredCacheSize -gt ($FreeDiskSpace * 1000)){
$DesiredCacheSize = [Math]::Round(((($DiskFreePercent/2) * .01) * $TotalDiskSpace) * 1000)
}

IF($DesiredCacheSize -lt $MinimumCacheSize){
$DesiredCacheSize = $MinimumCacheSize
}

IF($CCMCache.Size -lt $DesiredCacheSize){
$ChangeCacheFlag = $True
}else{
$ChangeCacheFlag = $False
}

#"$($DiskFreePercent)% of disk free"
#"$($CacheUsedPercent)% of cache used"

IF(($CacheUsedPercent -ge 75) -or ($DiskFreePercent -le 5) -or ($ChangeCacheFlag)){
$ClearCacheFlag = $True
}
Else{
$ClearCacheFlag = $False
}

IF($ClearCacheFlag){
    ## Get Cache Elements
    $CMObject = New-Object -ComObject "UIResource.UIResourceMGR"
    $CMCacheObject = $CMObject.GetCacheInfo()
    $CMCacheElementObject = $CMCacheObject.GetCacheElements()

    ## Loop the cache, deleting any object that isn't running in the current cache directory
    Foreach ($i in $CMCacheElementObject){
            IF(($i.LastReferenceTime.AddHours(-4) -lt (Get-Date).AddDays(-30)) -or ((Get-Item $i.Location).LastWriteTime -lt (Get-Date).AddDays(-30))){
                $CMCacheObject.DeleteCacheElement($i.CacheElementID)
            }
    }

}

IF($ChangeCacheFlag){
# Change CacheSize
IF($CCMCache.Location -ne "C:\Windows\ccmcache"){
$CCMCache.Location = "C:\Windows\ccmcache"
}
$CCMCache.Size = $DesiredCacheSize
$CCMCache.Put()

# restart SMS Agent Host
Restart-Service ccmexec -Force
Start-Sleep -Seconds 5
# Request Machine Policy
Invoke-WmiMethod -Namespace root\ccm -Class SMS_Client -Name RequestMachinePolicy -ArgumentList 1 | Out-Null
Start-Sleep -Seconds 5
Invoke-WmiMethod -Namespace root\CCM -Class SMS_Client -Name TriggerSchedule '{00000000-0000-0000-0000-000000000021}' | Out-Null
Start-Sleep -Seconds 5
Invoke-WmiMethod -Namespace root\CCM -Class SMS_Client -Name TriggerSchedule '{00000000-0000-0000-0000-000000000121}' | Out-Null
}
