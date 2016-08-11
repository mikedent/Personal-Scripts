#requires -Version 1
#requires -PSSnapin VMware.VimAutomation.Core
<#	
    .NOTES
    ===========================================================================
    Created on:   	4/21/2015 6:16 PM
    Created by:   	Mike Dent
    Organization: 	
    Filename:   	SetNtp.ps1  	
    ===========================================================================
    .DESCRIPTION
    Script to set the NTP values across all hosts connected to vCenter.  
    Script will set the NTP service policy to automatic, and restart the service
#>
$VIServer = '172.91.0.180'
$User = 'administrator@acso.local'
$Pass = 'Tr!t3cH1'
#Add-PSSnapin VMware.VimAutomation.Core
Connect-VIServer -Server $VIServer  -User $User -Password $Pass
$NTPServers = ('10.255.255.249')
$ESXhosts = Get-VMHost
foreach ($ESX in $ESXhosts)
{
  Write-Host -Object "Target = $ESX"
  $NTPList = Get-VMHostNtpServer -VMHost $ESX
  Remove-VMHostNtpServer -VMHost $ESX -NtpServer $NTPList -Confirm:$false
  Add-VMHostNtpServer -VMHost $ESX -NtpServer $NTPServers -Confirm:$false
  Set-VMHostService -HostService (Get-VMHostService -VMHost (Get-VMHost $ESX) | Where-Object -FilterScript {
      $_.key -eq 'ntpd'
  }) -Policy 'Automatic'
  Get-VMHostFirewallException -VMHost $ESX -Name 'NTP Client' | Set-VMHostFirewallException -Enabled:$true
  $ntpd = Get-VMHostService -VMHost $ESX | Where-Object -FilterScript {
    $_.Key -eq 'ntpd'
  }
  Restart-VMHostService -HostService $ntpd -Confirm:$false
}
Disconnect-VIServer * -Force