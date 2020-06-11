#requires -Version 1
#requires -PSSnapin VMware.VimAutomation.Core
<#	
    .NOTES
    ===========================================================================
    Created on:   	4/22/2015 5:55 PM
    Created by:   	Mike
    Organization: 	
    Filename:     	
    ===========================================================================
    .DESCRIPTION
    A description of the file.
#>

# Set vSphere

$vSphereServer = Read-Host -Prompt 'Enter the vCenter Server'
$SyslogServer = Read-Host -Prompt 'Enter the Syslog Server'

# Set Logging Settings
#$logHost = "udp://$logServer:514"
#$logSize = "10240" #10mb
#$logRotate = "20"

################################# start functions

#################################
#check vmware powercli is registered. PowerCLI must be installed.
Function Add-PowerCLI
{
  $snapinInstalled = Get-PSSnapin -Registered
  if ($snapinInstalled -like '*VimAuto*')
  {
    Write-Host -Object 'PowerCLI installed'
  }
  Else
  {
    Write-Host -Object 'PowerCLI not installed....installing'
    Add-PSSnapin -Name 'Vmware.VimAutomation.Core'
    if ($? -eq $FALSE)
    {
      Write-Host -Object 'PowerCLI is not installed - Please install.......quiting'
      exit
    }
  }
}

Function Check-Error ($name)
{
  if ($? -eq $FALSE)
  {
    Write-Host -Object "$name failed" -ForegroundColor Red
  }
  else
  {
    Write-Host -Object "$name succeeded" -ForegroundColor Green
  }
}
function Set-VMHostLogs ($vSphereServer,$logHost,$logSize,$logRotate)
{

} 

function Get-VMHostsLogs ($esxHost)
{
  $readLogHost = Get-VMHostAdvancedConfiguration -VMHost $esxHost -Name Syslog.global.logHost
  $readDefaultSize = Get-VMHostAdvancedConfiguration -VMHost $esxHost -Name Syslog.global.defaultsize
  $readRotate = Get-VMHostAdvancedConfiguration -VMHost $esxHost -Name Syslog.global.defaultRotate
  Write-Host $esxHost $readLogHost.keys $readLogHost.Values
  Write-Host $esxHost $readDefaultSize.keys $readDefaultSize.Values
  Write-Host $esxHost $readRotate.keys $readRotate.Values
}

################################# End functions

#################################
# Start Main Script 

Write-Host -Object 'This script will change the Syslog Server on all hosts within a vCenter, restart Syslog, and open any required ports.'
 
Write-Host
 
$mySyslog = Read-Host -Prompt 'Enter new Syslog Server. e.g. udp://10.0.0.1:514'
 
Write-Host
 
foreach ($myHost in Get-VMHost)
{
  #Display the ESXi Host being modified
  Write-Host '$myHost = ' $myHost
 
  #Set the Syslog Server
  $myHost |
  Get-AdvancedSetting -Name Syslog.global.logHost |
  Set-AdvancedSetting -Value $mySyslog -Confirm:$FALSE
 
  #Restart the syslog service
  $esxcli = Get-EsxCli -VMHost $myHost
  $esxcli.system.syslog.reload()
 
  #Open firewall ports
  Get-VMHostFirewallException -Name 'syslog' -VMHost $myHost | Set-VMHostFirewallException -Enabled:$true
}
Disconnect-VIServer -Confirm:$FALSE
  