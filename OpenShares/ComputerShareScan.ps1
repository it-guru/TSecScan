[CmdletBinding()]
param(
   [string]$Config = "\etc\OpenShares.ini",
   [string]$DatabaseDir = "\tmp",
   [string]$ExportDir = "\tmp"
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

Write-Log "DatabaseDir : '$DatabaseDir'"
Write-Log "ExportDir   : '$ExportDir'"

if ( -not (Test-Path $DatabaseDir) ){
   Write-Error "Directory Tmp='$DatabaseDir' not exists"
   exit
}

function Process-NetComputerFile {
    Param (
        [Parameter(ValueFromPipeline=$True)]
        [Alias('File')]
        [String]
        $InFile="",
        [String]
        $OutFile=""

    )
    if ( -not ($OutFile -eq "")){
       if (Test-Path($OutFile)){
          Clear-Content $OutFile;
       }
       If ((Get-Item $InFile).length -gt 0) {
          Invoke-XxXShareFinder -ComputerFile $InFile -Threads 100 | %{
              $ShareName=$_ -replace " .*$","";
              Write-Output $ShareName;
          } > $OutFile
       }
    }
}


function Start-ShareScan {
   $inset=$true;
   for($fno=1;$fno -lt 1000;$fno++){
      $f="$DatabaseDir\ComputerIP_{0:d3}.txt" -f $fno;
      $OutFile="$DatabaseDir\ComputerShare_{0:d3}" -f $fno;
      if ($inset){
         if (Test-Path($f)){
            $s="Start processing {0}" -f $d,$f;
            Write-Log $s;
            Process-NetComputerFile -InFile $f -OutFile "$OutFile.tmp";
            Move-Item -Force -Path "$OutFile.tmp" -Destination "$OutFile.csv"
         }
         else{
            $inset=$false;
         }
      }
      if (-not ($inset)){
         Get-Item "$OutFile.*" | Remove-Item -Force
      }
   }
}


Start-ShareScan





