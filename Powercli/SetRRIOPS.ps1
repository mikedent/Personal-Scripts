Connect-VIServer -Server 10.2.225.135 -User administrator@vsphere.local -Password 'Tr!t3cH1'
$ESXiHosts = Get-Cluster 'CAD' | Get-VMHost
foreach ($ESXi in $ESXiHosts)
{
Get-VMhost $ESXi | Get-ScsiLun -LunType Disk | Where-Object {$_.CanonicalName -like 'naa.*' -and $_.MultipathPolicy -like 'RoundRobin'} | Set-ScsiLun -CommandsToSwitchPath 1
}

Get-VMHost | Get-ScsiLun -LunType Disk | Where-Object {$_.MultiPathPolicy -like 'RoundRobin'} | Select-Object CanonicalName, MultipathPolicy, CommandsToSwitchPath