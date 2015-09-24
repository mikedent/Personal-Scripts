<#	
	.NOTES
	===========================================================================
	 Created on:   	9/18/2015 
	 Created by:   	Mike Dent
	 Organization: 	
	 Filename:   	EnableSSH.ps1  	
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
$ESXhosts = get-vmhost
foreach ($ESX in $ESXHosts)

foreach($ESX in $ESXHosts){
    write-host "Configuring SSH on host: $($ESX.Name)" -fore Yellow
    if((Get-VMHostService -VMHost $ESX | where {$_.Key -eq "TSM-SSH"}).Policy -ne "on"){
        Write-Host "Setting SSH service policy to automatic on $($ESX.Name)"
        Get-VMHostService -VMHost $ESX | where { $_.key -eq "TSM-SSH" } | Set-VMHostService -Policy "On" -Confirm:$false -ea 1 | Out-null
    }

    if((Get-VMHostService -VMHost $ESX | where {$_.Key -eq "TSM-SSH"}).Running -ne $true){
        Write-Host "Starting SSH service on $($ESX.Name)"
        Start-VMHostService -HostService (Get-VMHost $ESX | Get-VMHostService | Where { $_.Key -eq "TSM-SSH"}) | Out-null
    }    
    
    
    if(($ESX | Get-AdvancedSetting | Where {$_.Name -eq "UserVars.SuppressShellWarning"}).Value -ne "1"){
        Write-Host "Suppress the SSH warning message"
        $ESX | Get-AdvancedSetting | Where {$_.Name -eq "UserVars.SuppressShellWarning"} | Set-AdvancedSetting -Value "1" -Confirm:$false | Out-null
    }    
}