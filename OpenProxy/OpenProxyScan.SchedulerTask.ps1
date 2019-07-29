param(
   [string]$Config     = "\etc\SchedulerTask.ini",
   [string]$LogDir     = "\tmp",
   [string]$User       = "nobody",
   [string]$Password   = "nopass"
)

$MyDir   =[System.IO.Path]::GetDirectoryName($myInvocation.MyCommand.Definition)
$MyApp   =[System.IO.Path]::GetFileName($MyInvocation.MyCommand.Name)
$MyDrive =Split-Path -Path $MyDir -Qualifier
$MyName  =Split-Path -Path $MyApp -Leaf
$MyCampania=Split-Path -Path $MyDir -Leaf

Set-Location $MyDrive
$env:PSModulePath = $env:PSModulePath + ';'+$MyDir+'\..\PowerLib';
Import-Module -Name ScanKernel

Write-Log "Start $MyName";

Write-Log "Path        : '$MyDir'";
Write-Log "Drive       : '$MyDrive'";
Write-Log "Campania    : '$MyCampania'";

Import-Module -Name Recon
Import-Module -Name ConfigFile

Import-ConfigFile -Ini -ErrorAction Stop -ConfigFilePath $Config

$MyJobname=$MyName -replace "\.SchedulerTask.ps1$","";

Write-Log "Jobname     : '$MyJobname'";
Write-Log "User        : '$User'";
Write-Log "LogDir      : '$LogDir'";

$taskName="TSecScan-$MyCampania-$MyJobname";

$taskExists = Get-ScheduledTask | Where-Object {$_.TaskName -like $taskName }

if ($taskExists){
   Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
}
$maxduration = (New-TimeSpan -Hours 4)

$cmd="-ExecutionPolicy Bypass -NoProfile ""& "+ `
     "'$MyDir\$MyJobname.ps1' "+ `
     " -Config \etc\$MyCampania.ini "+ `
     ">>$LogDir\$MyCampania-$MyJobname.log 2>&1 "" ";

$TaskTrigger = New-ScheduledTaskTrigger -At 20:50 -Daily;
$TaskAction  = New-ScheduledTaskAction -Execute powershell.exe `
                                       -Argument $cmd `
                                       -WorkingDirectory "$MyDir\"; 
$TaskSettings= New-ScheduledTaskSettingsSet -ExecutionTimeLimit $maxduration;


$nTask=Register-ScheduledTask -TaskName $TaskName `
                       -Trigger $TaskTrigger `
                       -Settings $TaskSettings `
                       -User $User -Password $Password `
                       -Action $TaskAction;

$nTask.Triggers.Repetition.Duration="P1D";
$nTask.Triggers.Repetition.Interval ="PT4H";

$n=$nTask | Set-ScheduledTask -Password $Password -User $User

