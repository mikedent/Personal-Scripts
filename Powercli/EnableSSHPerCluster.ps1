#requires -Version 1
#requires -PSSnapin VMware.VimAutomation.Core
########### vCenter Connectivity Details ###########

Write-Host -Object 'Please enter the vCenter Host IP Address:' -ForegroundColor Yellow -NoNewline
$VMHost     = Read-Host
Write-Host -Object 'Please enter the vCenter Username:' -ForegroundColor Yellow -NoNewline
$User       = Read-Host
Write-Host -Object 'Please enter the vCenter Password:' -ForegroundColor Yellow -NoNewline
$Pass       = Read-Host
Connect-VIServer -Server $VMHost -User $User -Password $Pass

########### Please Enter the Cluster to Enable SSH ###########
Write-Host -Object 'Clusters Associated with this vCenter:' -ForegroundColor Green
$VMcluster  = '*'
ForEach ($VMcluster in (Get-Cluster -Name $VMcluster)| Sort-Object)
{
  Write-Host -Object $VMcluster
}
Write-Host -Object 'Please enter the Cluster to Enable/Disable SSH:' -ForegroundColor Yellow -NoNewline
$VMcluster  = Read-Host

########### Enabling SSH ###########
Write-Host -Object 'Ready to Enable SSH? ' -ForegroundColor Yellow -NoNewline
Write-Host -Object ' Y/N:' -ForegroundColor Red -NoNewline
$SSHEnable  = Read-Host
if ($SSHEnable -eq 'y') 
{
  Write-Host -Object 'Enabling SSH on all hosts in your specified cluster:' -ForegroundColor Green
  Get-Cluster $VMcluster |
  Get-VMHost |
  ForEach-Object -Process {
    Start-VMHostService -HostService ($_ |
      Get-VMHostService |
      Where-Object -FilterScript {
        $_.Key -eq 'TSM-SSH'
    })
  }
}

########### Disabling SSH ###########
Write-Host -Object 'Ready to Disable SSH? ' -ForegroundColor Yellow -NoNewline
Write-Host -Object ' Y/N:' -ForegroundColor Red -NoNewline
$SSHDisable = Read-Host
if ($SSHDisable -eq 'y') 
{
  Write-Host -Object 'Disabling SSH' -ForegroundColor Green
  Get-Cluster $VMcluster |
  Get-VMHost |
  ForEach-Object -Process {
    Stop-VMHostService -HostService ($_ |
      Get-VMHostService |
      Where-Object -FilterScript {
        $_.Key -eq 'TSM-SSH'
    }) -Confirm:$FALSE
  }
}
