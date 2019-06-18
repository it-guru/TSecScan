ListenerScan.ps1:
=================
  Default-Config : \etc\ListenerScan.ini
  Input          : $ControlDir\Networks.csv
  Output         : $DatabaseDir\Network\*
                   $ExportDir\NetworkNodes*.csv

Reads the network list from $ControlDir\Networks.csv and do a nmap
networkscan on each network. The $Ports will be scaned to detect up/running
nodes.


  $ExportDir\NetworkNodes*.csv
  Host     : IP-Adress of up/running Host
  DNSName  : If a DNS name has been detected, it will be stored in this column
  Ports    : founded active listners



ListenerScan.SchedulerTask.ps1:
===============================
  Default-Config : \etc\SchedulerTask.ini

Creates a SchedulerTask for ListenerScan.ps1 . The Parameter $LocalAdminUser
and $LocalAdminUserPassword must be set. 

