param (
    [string]$TSName
    )

$t = '[DllImport("user32.dll")] public static extern bool ShowWindow(int handle, int state);'
add-type -name win -member $t -namespace native
[native.win]::ShowWindow(([System.Diagnostics.Process]::GetCurrentProcess() | Get-Process).MainWindowHandle, 0)

Import-Module $PSSCriptRoot\BurntToast\BurntToast.psm1
New-BurntToastNotification -Text "New Feature Update Available!","The $TSName is available for you to install in the Software Center" -Button (New-BTButton -Content "Learn More" -Arguments 'softwarecenter:SoftwareID=ScopeId_DACA6630-B49D-4AC2-BCCD-6C46A77E0AC1/Application_1dbcbf82-f138-4a79-9b14-eeb24d1e872b') -AppLogo $PSScriptRoot\icon.ico
