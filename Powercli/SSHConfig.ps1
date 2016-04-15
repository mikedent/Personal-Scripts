
########### vCenter Connectivity Details ###########
Write-Host 'Please enter the vCenter Host IP Address:'� -ForegroundColor Yellow -NoNewline
$VMHost = Read-Host
Write-Host 'Please enter the vCenter Username:” -ForegroundColor Yellow -NoNewline
$User = Read-Host
Write-Host 'Please enter the vCenter Password:” -ForegroundColor Yellow -NoNewline
$Pass = Read-Host
Connect-VIServer -Server $VMHost -User $User -Password $Pass
########### vCenter Connectivity Details ###########

########### Please Enter the Cluster to Enable SSH ###########
Write-Host 'Clusters Associated with this vCenter:” -ForegroundColor Green
$VMcluster = '*'
ForEach ($VMcluster in (Get-Cluster -name $VMcluster)| sort)
{
Write-Host $VMcluster
}
Write-Host 'Please enter the Cluster to Enable/Disable SSH:” -ForegroundColor Yellow -NoNewline
$VMcluster = Read-Host
########### Please Enter the Cluster to Enable SSH ###########

########### Enabling SSH ###########
Write-Host 'Ready to Enable SSH? ' -ForegroundColor Yellow -NoNewline
Write-Host ' Y/N: ' -ForegroundColor Red -NoNewline
$SSHEnable = Read-Host
if ($SSHEnable -eq 'y') {
Write-Host 'Enabling SSH on all hosts in your specified cluster:' -ForegroundColor Green
Get-Cluster $VMcluster | Get-VMHost | ForEach {Start-VMHostService -HostService ($_ | Get-VMHostService | Where {$_.Key -eq 'TSM-SSH”})}
}
########### Enabling SSH ###########

########### Disabling SSH ###########
Write-Host 'Ready to Disable SSH? ' -ForegroundColor Yellow -NoNewline
Write-Host 'Y/N:'' -ForegroundColor Red -NoNewline
$SSHDisable = Read-Host
if ($SSHDisable -eq 'y”) {
Write-Host 'Disabling SSH” -ForegroundColor Green
Get-Cluster $VMcluster | Get-VMHost | ForEach {Stop-VMHostService -HostService ($_ | Get-VMHostService | Where {$_.Key -eq 'TSM-SSH”}) -Confirm:$FALSE}
}
########### Disabling SSH ###########