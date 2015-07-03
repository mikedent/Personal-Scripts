<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2015 v4.2.82
	 Created on:   	4/21/2015 6:16 PM
	 Created by:   	Mike Dent
	 Organization: 	
	 Filename:   	SetNtp.ps1  	
	===========================================================================
	.DESCRIPTION
		Script to set the NTP values across all hosts connected to vCenter.  
		Script will set the NTP service policy to automatic, and restart the service
#>
$VIServer = "172.30.3.3"
$User = "administrator@vsphere.local"
$Pass = "G0lden*ak"
#Add-PSSnapin VMware.VimAutomation.Core
Connect-VIServer $VIServer  -User $User -Password $Pass
$NTPServers = ("128.138.141.172","129.6.15.30")
$ESXhosts = get-vmhost
foreach ($ESX in $ESXHosts)
{
	Write-Host "Target = $ESX"
	$NTPList = Get-VMHostNtpServer -VMHost $ESX
	Remove-VMHostNtpServer -VMHost $ESX -NtpServer $NTPList -Confirm:$false
	Add-VMHostNtpServer -VMHost $ESX -NtpServer $NTPServers -Confirm:$false
	Set-VMHostService -HostService (Get-VMHostservice -VMHost (Get-VMHost $ESX) | Where-Object { $_.key -eq "ntpd" }) -Policy "Automatic"
	Get-VmhostFirewallException -VMHost $ESX -Name "NTP Client" | Set-VMHostFirewallException -enabled:$true
	$ntpd = Get-VMHostService -VMHost $ESX | where { $_.Key -eq 'ntpd' }
	Restart-VMHostService $ntpd -Confirm:$false
}
Disconnect-VIServer -Force