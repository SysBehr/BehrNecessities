# User
$skypeExtu = Get-Item "HKCU:\Software\Microsoft\Office\Outlook\Addins\UCAddin.LyncAddin.1" -ErrorAction SilentlyContinue
$skypeAutorun = Get-ItemProperty HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run -Name Lync -ErrorAction SilentlyContinue

IF($skypeExtu) { Remove-ITem $skypeExtu.PSPath }

IF($skypeAutorun){ Remove-ItemProperty $skypeAutorun.PSPath -Name "Lync" }
