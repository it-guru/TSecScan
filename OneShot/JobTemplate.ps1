[CmdletBinding()]
param(
   [string]$Config = "\etc\OneShot.ini",
   [string]$DatabaseDir = "\database",
   [string]$ExportDir = "\export",
   [long]$MaxWorkTime = 3600
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

if (Test-Path $Config){
   Import-ConfigFile -Ini -ErrorAction Stop -ConfigFilePath $Config 
}

$StartDate=Get-Date;
$TimedOut=$false;

Write-Log "DatabaseDir : '$DatabaseDir'"
Write-Log "ExportDir   : '$ExportDir'"
Write-Log "MaxWorkTime : '$MaxWorkTime'"

$OutFile="$ExportDir\OneShot.csv";
if ( -not (Test-Path $OutFile)){
   Set-Content $OutFile -Value ("SecToken;ScanDate;IPAddress;TreatRules" + `
                                ";SecItem;SecCampaign;SecDetailSpec");
   "SampleToken01;2000-01-01 00:00:00;"+ `
   "1.2.3.4;IgnoreFinding;SAMPLE01;"+ `
   "OneShot Campaign;" | Add-Content $OutFile

   "SampleToken02;2000-01-01 00:00:00;"+ `
   "1.1.2.2 33.44.55.66;IgnoreFinding;SAMPLE01;"+ `
   "OneShot Campaign;" | Add-Content $OutFile

   "SampleToken03 [FE80:0000:0000:0000:0202:B3FF:FE1E:8329]:80;"+ `
   "2000-01-01 01:00:00;"+ `
   "FE80:0000:0000:0000:0202:B3FF:FE1E:8329;IgnoreFinding;SAMPLE03;"+ `
   "OneShot Campaign;" | Add-Content $OutFile
}

