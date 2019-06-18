ListenerScan.ps1:
=================
  Default-Config : \etc\ListenerScan.ini
  Input          : $ControlDir\Networks.csv
  Output         : $DatabaseDir\Network\*
                   $ExportDir\NetworkNodes*.csv

Reads the network list from $ControlDir\Networks.csv and do a nmap
networkscan on each network. The $Ports will be scaned to detect up/running
nodes.

Export:
-------
  $ExportDir\NetworkNodes*.csv
  Host     : IP-Adress of up/running Host
  DNSName  : If a DNS name has been detected, it will be stored in this column
  Ports    : founded active listners

Dependencies:
-------------
 + nmap for Windows needs to be installed and in the 
   PATH at min. version 7.70 from https://nmap.org/download.html

 + For SchedulerTask a local Admin User $LocalAdminUser and 
   $LocalAdminUserPassword is needed. The User $LocalAdminUser needs to be
   member of local Administrators.


ListenerScan.SchedulerTask.ps1:
===============================
  Default-Config : \etc\SchedulerTask.ini

Creates a SchedulerTask for ListenerScan.ps1 . The Parameter $LocalAdminUser
and $LocalAdminUserPassword must be set. 

