$CCMCache = Get-WmiObject -Namespace "ROOT\CCM\SoftMgmtAgent" -Class CacheConfig
$c = Gwmi Win32_Volume | Where {$_.Name -eq 'C:\'} | Select Capacity,FreeSpace

$TotalDiskSpace = [Math]::Round($c.Capacity/1GB,2)
$FreeDiskSpace = [Math]::Round($c.FreeSpace/1GB,2)

$TotalCacheSize = [Math]::Round($CCMCache.size/1000,2)
$UsedCacheSize = [Math]::Round(((Get-ChildItem $CCMCache.Location -Recurse -Force | Measure-Object -Property Length -Sum -ErrorAction Stop).Sum / 1GB),2)

$DiskFreePercent = [Math]::Round(($FreeDiskSpace/$TotalDiskSpace),2)*100
$CacheUsedPercent = [Math]::Round($UsedCacheSize/$TotalCacheSize,2)*100

$DesiredCacheSize = <# 10% of Disk #> ($TotalDiskSpace * .10) * 1000
$MinimumCacheSize = 51240

#If Desired Cache is greater than MB free on disk, set it to 50% of available FreeSPace
If($DesiredCacheSize -gt ($FreeDiskSpace * 1000)){
$DesiredCacheSize = [Math]::Round(((($DiskFreePercent/2) * .01) * $TotalDiskSpace) * 1000)
}

IF($DesiredCacheSize -lt $MinimumCacheSize){
$DesiredCacheSize = $MinimumCacheSize
}

IF($CCMCache.Size -lt $DesiredCacheSize){
Return $True
}

IF(($CacheUsedPercent -ge 75) -or ($DiskFreePercent -le 5) -or ($ChangeCacheFlag)){
Return $True
}

Return $False
