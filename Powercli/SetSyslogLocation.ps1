  <#	
          .NOTES
          ===========================================================================
          Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2015 v4.2.82
          Created on:   	4/22/2015 5:55 PM
          Created by:   	Mike
          Organization: 	
          Filename:     	
          ===========================================================================
          .DESCRIPTION
          A description of the file.
  #>

  # Set vSphere

  $vSphereServer = Read-Host "Enter the vCenter Server"
  $SyslogServer = Read-Host "Enter the Syslog Server"

  # Set Logging Settings
  #$logHost = "udp://$logServer:514"
  #$logSize = "10240" #10mb
  #$logRotate = "20"

  ################################# start functions

  #################################
  #check vmware powercli is registered. PowerCLI must be installed.
  Function Add-PowerCLI
  {
      $snapinInstalled = Get-PSSnapin -registered
      if ($snapinInstalled -like "*VimAuto*")
      {
          Write-host "PowerCLI installed"
      }
      Else
      {
          write-host "PowerCLI not installed....installing"
          Add-PSSnapin "Vmware.VimAutomation.Core"
          if ($? -eq $FALSE)
          {
              write-host "PowerCLI is not installed - Please install.......quiting"
              exit
          }
      }
  }

  Function Check-Error ($name)
  {
      if ($? -eq $FALSE)
      {
          write-host "$name failed" -ForegroundColor Red
      }
      else
      {
          write-host "$name succeeded" -ForegroundColor Green
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
      write-host $esxHost $readLogHost.keys $readLogHost.Values
      write-host $esxHost $readDefaultSize.keys $readDefaultSize.Values
      write-host $esxHost $readRotate.keys $readRotate.Values
  }

  ################################# End functions

  #################################
  # Start Main Script 

  Write-Host "This script will change the Syslog Server on all hosts within a vCenter, restart Syslog, and open any required ports."
 
  Write-Host
 
  $mySyslog = Read-Host "Enter new Syslog Server. e.g. udp://10.0.0.1:514"
 
  Write-Host
 
  foreach ($myHost in get-VMHost)
  {
      #Display the ESXi Host being modified
      Write-Host '$myHost = ' $myHost
 
      #Set the Syslog Server
      $myHost | Get-AdvancedSetting -Name Syslog.global.logHost | Set-AdvancedSetting -Value $mySyslog -Confirm:$false
 
      #Restart the syslog service
      $esxcli = Get-EsxCli -VMHost $myHost
      $esxcli.system.syslog.reload()
 
      #Open firewall ports
      Get-VMHostFirewallException -Name "syslog" -VMHost $myHost | set-VMHostFirewallException -Enabled:$true
  }
  disconnect-viserver -Confirm:$false
  