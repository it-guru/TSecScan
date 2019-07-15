param(
   [string]$Config     = "\etc\BlueKeepRDP.ini",
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

$StartDate=Get-Date;
$TimedOut=$false;


$NetworksFile="$ControlDir/Networks.csv";

if ( -not (Test-Path $DB) ){
   Write-Error "Directory DB='$DB' not exists"
   exit
}
if ( -not (Test-Path "$NetworksFile")){
   Write-Error "No Networks.csv found '$NetworksFile' "
   exit
}

if ( -not (Test-Path "$DB\BlueKeep")){
   New-Item -ItemType directory -Force -Path "$DB\BlueKeep"
}



for($fnum=1;$fnum -le 99; $fnum++){
   $InFile="$DB\Network\Nodes_{0:d4}" -f $fnum;
   $OutFile="$DB\BlueKeep\BlueKeep_{0:d4}" -f $fnum;
   $now=Get-Date;
   if ((New-TimeSpan -Start $StartDate -End $now).TotalSeconds `
       -gt $MaxWorkTime){
      $TimedOut=$true;
   }
   else{
      if (-not ($TimedOut)){
         if (Test-Path "$InFile.csv"){
            Write-Log "start Processing to $OutFile.csv1";
            Get-Content "$InFile.csv" | foreach-object {
               $csvline=$_.split(";");
               $pline=$csvline[2];
               $pline=
               $pline=[regex]::replace($csvline[2], "^.*:","");
               $plst=$pline.split(",");
               if ($plst -match "3389/open"){
                  Write-Output $csvline[0];
               }
            } | & 'rdpscan' --workers 300 --file - | foreach-object {
               $l=[regex]::split($_," - ");
               $treatRules="IgnoreFinding";
               if ($l[1] -match "VULNERABLE"){
                  $treatRules="EnforceRemove";
               }
               $token="BlueKeep:$($l[0]):RDP";
               $ipaddr=$l[0];
               if (-not ($ipaddr -eq "")){
                  $d=(Get-Date).ToUniversalTime().ToString(`
                     "yyyy-MM-dd HH:mm:ss");
                  Write-Output ("$token;$d;"+ `
                                "$ipaddr;$treatRules;BLUEKEEP001;"+ `
                                "BlueKeep");
               }
            }  > "$OutFile.tmp"
            Move-Item -Force -Path "$OutFile.tmp" `
                             -Destination "$OutFile.csv1"
            Copy-Item -Force -Path "$OutFile.csv1" `
                             -Destination "$OutFile.csv"
            Write-Log "finish file $OutFile.csv"
         }
         else{
            Get-Item "$OutFile.*" | Remove-Item
         }
      }
   }
}
if (-not ($TimedOut)){
   Write-Host "cleanup csv1 files"
   Get-Item "$DB\BlueKeep\BlueKeep_*.csv1" | Remove-Item -Force
}

Get-Item "$ExportDir\BlueKeepRDP_*.csv" | Remove-Item -Force
$d=Get-Date -Format "yyyyMMdd-HHmmss";
$OutFile="$ExportDir\BlueKeepRDP_$d.csv";
Set-Content $OutFile -Value ("SecToken;ScanDate;IPAddress;TreatRules" + `
                             ";SecItem;SecCampaign");
Get-Content "$DB\BlueKeep\BlueKeep_*.csv" | Add-Content $OutFile




