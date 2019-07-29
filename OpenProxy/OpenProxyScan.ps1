param(
   [string]$Config     = "\etc\OpenProxy.ini",
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



if ( -not (Test-Path $DB) ){
   Write-Error "Directory DB='$DB' not exists"
   exit
}

if ( -not (Test-Path "$DB\OpenProxy")){
   New-Item -ItemType directory -Force -Path "$DB\OpenProxy"
}


$proxyscanBlock= {
   Param (
       [String]
       $ComputerName=$null,
       [String]
       $Drive=$null,
       [String]
       $Ports=$null
   )
   Write-Host "Start Scan on $ComputerName"
   $proxy = new-object System.Net.WebProxy("http://"+$ComputerName);
   #$proxy = new-object System.Net.WebProxy("http://127.0.0.1:3128");
   $proxy.useDefaultCredentials = $true
   $testurl   = "http://dnsresolver.w5base.net/W5ProbeIP"
   $testmatch = "<title>W5ProbeIP</title>"
   $UserAgent = new-object system.net.WebClient
   $UserAgent.proxy = $proxy
   $content=""
   try{
      $webpage = $UserAgent.DownloadData($testurl)
      $content = [System.Text.Encoding]::ASCII.GetString($webpage)
   }
   catch{

   }
   if ($content -match $testmatch){
      $token="OpenProxy:$ComputerName";
      $ipaddr=[regex]::replace($ComputerName,":.*$","");
      $port=[regex]::replace($ComputerName,"^.*:","");
      $ClientIP="notDetected";
      $treatRules="EnforceRemove";
      $found = $content -match '>ClientIP:([^<]{8,25})<'
      if ($found) {
          $ClientIP = $matches[1]
      }
      if (-not ($ipaddr -eq "")){
         $d=(Get-Date).ToUniversalTime().ToString(`
            "yyyy-MM-dd HH:mm:ss");
         Write-Output ("$token;$d;"+ `
                       "$ipaddr;$treatRules;OPENPROXY01;"+ `
                       "OpenProxy;$port;$ClientIP");
      }
   }
}






for($fnum=1;$fnum -le 9999; $fnum++){
   $InFile="$DB\Network\Nodes_{0:d4}" -f $fnum;
   $OutFile="$DB\OpenProxy\OpenProxy_{0:d4}" -f $fnum;
   $now=Get-Date;
   if ((New-TimeSpan -Start $StartDate -End $now).TotalSeconds `
       -gt $MaxWorkTime){
      $TimedOut=$true;
   }
   else{
      if (-not ($TimedOut)){
         if (Test-Path "$InFile.csv"){
            if (-not (Test-Path "$OutFile.csv1")){
               Write-Log "start Processing to $OutFile.csv1";
               Get-Content "$InFile.csv" | foreach-object {
                  $csvline=$_.split(";");
                  $pline=$csvline[2];
                  $pline=
                  $pline=[regex]::replace($csvline[2], "^.*:","");
                  $plst=$pline.split(",");
                  if ($plst -match "3128/open"){
                     $line=$csvline[0];
                     $line+=":3128";
                     Write-Output $line;
                  }
                  if ($plst -match "8080/open"){
                     $line=$csvline[0];
                     $line+=":8080";
                     Write-Output $line;
                  }
                } > "$OutFile.in"
                if ((Get-Item "$OutFile.in").length -gt 0kb){ 
                    $ipList=Get-Content "$OutFile.in"
                   Invoke-XxXThreadedFunction -Verbose -ComputerName $ipList `
                                              -ScriptBlock $proxyscanBlock `
                                              -Timeout 60 `
                                              -Threads 20 | Foreach-Object {
                      Write-Output $_;
                   }  > "$OutFile.tmp"
               }
               else{
                  set-content -Path ("$OutFile.tmp") -Force -Value ($null);
               }
               Move-Item -Force -Path "$OutFile.tmp" `
                                -Destination "$OutFile.csv1"
               Copy-Item -Force -Path "$OutFile.csv1" `
                                -Destination "$OutFile.csv"
               #Get-Item "$OutFile.in" | Remove-Item -Force
               Write-Log "finish file $OutFile.csv"
            }
         }
         else{
            Get-Item "$OutFile.*" | Remove-Item
         }
      }
   }
}
Write-Log "loop finished with TimedOut=$TimedOut"
if (-not ($TimedOut)){
   Write-Log "cleanup csv1 files"
   Get-Item "$DB\OpenProxy\OpenProxy_*.csv1" | Remove-Item -Force
   Get-Item "$DB\OpenProxy\OpenProxy_*.in" | Remove-Item -Force
}

Write-Log "removing old exports $ExportDir\OpenProxy_*.csv"
Get-Item "$ExportDir\OpenProxy_*.csv" | Remove-Item -Force
$d=Get-Date -Format "yyyyMMdd-HHmmss";
$OutFile="$ExportDir\OpenProxy_$d.csv";
Write-Log "build new $OutFile"
Set-Content $OutFile -Value ("SecToken;ScanDate;IPAddress;TreatRules" + `
                             ";SecItem;SecCampaign;ProxyPort;GatewayIP");
Get-Content "$DB\OpenProxy\OpenProxy_*.csv" | Add-Content $OutFile




