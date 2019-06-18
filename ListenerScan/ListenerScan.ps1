param(
   [string]$Config     = "\etc\ListenerScan.ini",
   [string]$Ports      = "22",
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
Write-Log "Ports         : '$Ports'"
Write-Log "MaxWorkTime   : '$MaxWorkTime'"
Write-Log ""

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

if ( -not (Test-Path "$DB\Network")){
   New-Item -ItemType directory -Force -Path "$DB\Network"
}





$NetList=Get-Content $NetworksFile;

for($fnum=0;$fnum -le 9999; $fnum++){
   $OutFile="$DB\Network\Nodes_{0:d4}" -f $fnum;
   $now=Get-Date;
   if ((New-TimeSpan -Start $StartDate -End $now).TotalSeconds -gt $MaxWorkTime){
      $TimedOut=$true;
   }
   else{
      if ($NetList[$fnum]){
         $csvline=$NetList[$fnum].split(";");
         if ( -not (Test-Path "$OutFile.csv1")){
            $networkspec=$csvline[0];
            Write-Log "start Processing $($networkspec) to $OutFile.csv1";
            Write-Output $networkspec | foreach-object {
               Write-Output $_ | & 'nmap' --min-rtt-timeout 2000ms `
                                          -initial-rtt-timeout 2000ms `
                                          -v -oG - -iL -  `
                                          -p $Ports
            } | foreach-object {
              if (-not ($_ -match "Status: Down")){
                 if ($_ -match "Ports:"){
                    $l=[regex]::split($_,"(\s*Host:\s*|\s*Ports:\s*)") | `
                                                           foreach-object {
                       $_.trim();
                    };
                    $rec = new-object System.Collections.Hashtable
                    for($i=1;$i -lt $l.Length;$i+=2) {
                       $k=$l[$i] -replace "[^a-z0-9A-Z]","";
                       $rec.Add($k,$l[$i+1]);
                    }
                    if ($rec.Host -match "[()]"){
                       $rec.DnsName=[regex]::replace($rec.Host, `
                                                     "^.* \((.+)\).*$",'$1');
                       $rec.Host=$rec.Host -replace " .*$","";
                    }
                    Write-Output "$($rec.Host);$($rec.DnsName);$($rec.Ports)";
                 }
              }
            } > "$OutFile.tmp"
            Move-Item -Force -Path "$OutFile.tmp" -Destination "$OutFile.csv1"
            Copy-Item -Force -Path "$OutFile.csv1" -Destination "$OutFile.csv"
         }
      }
      else{
         Get-Item "$OutFile.*" | Remove-Item
      }
   }
}
if (-not ($TimedOut)){
   Write-Host "cleanup csv1 files"
   Get-Item "$DB\Network\Nodes_*.csv1" | Remove-Item -Force
}

Get-Item "$ExportDir\NetworkNodes_*.csv" | Remove-Item -Force
$d=Get-Date -Format "yyyyMMdd-HHmmss";
$OutFile="$ExportDir\NetworkNodes_$d.csv";
Set-Content $OutFile -Value "Host;DNSName;Ports";
Get-Content "$DB\Network\Nodes_*.csv" | Add-Content $OutFile




