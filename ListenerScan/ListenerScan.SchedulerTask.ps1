param(
   [string]$Config     = "\etc\SchedulerTask.ini",
   [string]$LocalAdminUser          = "nobody",
   [string]$LocalAdminUserPassword  = "nopass"
)

$MyDir  =[System.IO.Path]::GetDirectoryName($myInvocation.MyCommand.Definition)
$MyApp  =[System.IO.Path]::GetFileName($MyInvocation.MyCommand.Name)
$MyDrive=Split-Path -Path $MyDir -Qualifier
$MyName =Split-Path -Path $MyApp -Leaf
Set-Location $MyDrive
$env:PSModulePath = $env:PSModulePath + ';'+$MyDir+'\..\PowerLib';
Import-Module -Name ScanKernel

Write-Log "Start $MyName";

Write-Log "Path        : '$MyDir'";
Write-Log "Drive       : '$MyDrive'";

Import-Module -Name Recon
Import-Module -Name ConfigFile

Import-ConfigFile -Ini -ErrorAction Stop -ConfigFilePath $Config

Write-Log "User        : '$LocalAdminUser'";

$taskName="TSecScan-ListenerScan"

$taskExists = Get-ScheduledTask | Where-Object {$_.TaskName -like $taskName }

if ($taskExists){
   Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
}
$repeat = (New-TimeSpan -Hours 4)
$maxduration = (New-TimeSpan -Hours 4)

$cmd='-ExecutionPolicy Bypass "& ''d:\Program Files\TSecScan\ListenerScan\ListenerScan.ps1'' -NoProfile -Config \etc\ListenerScan.ini >>D:\data\w5secscan\log\ListenerScan.log 2>&1'

$TaskTrigger = New-ScheduledTaskTrigger -At 19:10 -Daily;
$TaskAction  = New-ScheduledTaskAction -Execute powershell.exe `
                                       -Argument $cmd `
                                       -WorkingDirectory 'd:\'; 
$TaskSettings= New-ScheduledTaskSettingsSet -ExecutionTimeLimit $maxduration;


$nTask=Register-ScheduledTask -TaskName $TaskName `
                       -Trigger $TaskTrigger `
                       -Settings $TaskSettings `
                       -User $LocalAdminUser -Password $LocalAdminUserPassword `
                       -Action $TaskAction;

$nTask.Triggers.Repetition.Duration="P1D";
$nTask.Triggers.Repetition.Interval ="PT4H";

$n=$nTask | Set-ScheduledTask -Password $LocalAdminUserPassword `
                              -User $LocalAdminUser

