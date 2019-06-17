param(
   [string]$Config     = "\etc\Config.ini",
   [string]$ControlDir = "\tmp",
   [string]$DB         = "\tmp",
   [string]$AddPath    = $null, 
   [string]$ExportDir  = "\tmp",
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

Import-ConfigFile -Ini -ErrorAction Stop -ConfigFilePath $Config


if ($AddPath){
   $addPath.split(";") | foreach-object {
      if ( -not ($Env:Path.ToLower().split(";").contains($_.ToLower()))){
         $Env:path+=";"+$_;
      }
   }
}

# standard script variables 
Write-Log "DB            : '$DB'"
Write-Log "ExportDir     : '$ExportDir'"
Write-Log "ControlDir    : '$ControlDir'"
Write-Log "AddPath       : '$AddPath'"

# local script variables 
Write-Log "MaxWorkTime   : '$MaxWorkTime'"
Write-Log ""

$StartDate=Get-Date;
$TimedOut=$false;




