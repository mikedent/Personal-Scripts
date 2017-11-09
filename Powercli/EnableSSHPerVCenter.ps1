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
$VIServer = '10.10.201.10'
$User = 'administrator@vsphere.local'
$Pass = 'G0lden*ak'
#Add-PSSnapin VMware.VimAutomation.Core
Connect-VIServer -Server 10.10.201.10 -User administrator@vsphere.local -Password 'G0lden*ak'
$ESXhosts = Get-VMHost

foreach($ESX in $ESXhosts)
{
  Write-Host -Object "Configuring SSH on host: $($ESX.Name)" -ForegroundColor Yellow
  if((Get-VMHostService -VMHost $ESX | Where-Object -FilterScript {
        $_.Key -eq 'TSM-SSH'
  }).Policy -ne 'on')
  {
    Write-Host -Object "Setting SSH service policy to automatic on $($ESX.Name)"
    $null = Get-VMHostService -VMHost $ESX |
    Where-Object -FilterScript {
      $_.key -eq 'TSM-SSH' 
    } |
    Set-VMHostService -Policy 'On' -Confirm:$false -ea 1
  }

  if((Get-VMHostService -VMHost $ESX | Where-Object -FilterScript {
        $_.Key -eq 'TSM-SSH'
  }).Running -ne $true)
  {
    Write-Host -Object "Starting SSH service on $($ESX.Name)"
    $null = Start-VMHostService -HostService (Get-VMHost $ESX |
      Get-VMHostService |
      Where-Object -FilterScript {
        $_.Key -eq 'TSM-SSH'
    })
  }    
    
    
  if(($ESX |
      Get-AdvancedSetting |
      Where-Object -FilterScript {
        $_.Name -eq 'UserVars.SuppressShellWarning'
  }).Value -ne '1')
  {
    Write-Host -Object 'Suppress the SSH warning message'
    $null = $ESX |
    Get-AdvancedSetting |
    Where-Object -FilterScript {
      $_.Name -eq 'UserVars.SuppressShellWarning'
    } |
    Set-AdvancedSetting -Value '1' -Confirm:$false
  }    
}
Disconnect-VIServer * -Force -Confirm:$false