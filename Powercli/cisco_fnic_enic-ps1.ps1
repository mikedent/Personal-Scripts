##########################################################
#
# Confirm CISCO FNIC & ENIC Drivers 
#
# Date: 2016-07-01
#									 
# Created by: David Ring
#					 
##########################################################


################### vCenter Connectivity Details #######################

Write-Host "Please enter the vCenter Host IP Address:" -ForegroundColor Yellow -NoNewline
$VMHost = Read-Host

Write-Host "Please enter the vCenter Username:" -ForegroundColor Yellow -NoNewline
$User = Read-Host

Write-Host "Please enter the vCenter Password:" -ForegroundColor Yellow -NoNewline
$Pass = Read-Host

Connect-VIServer -Server $VMHost -User $User -Password $Pass



################### Please enter the Cluster to check CISCO Versions #######################
Write-Host "Clusters Associated with this vCenter:" -ForegroundColor Green

$VMcluster = '*'

ForEach ($VMcluster in (Get-Cluster -name $VMcluster)| sort)
{

Write-Host $VMcluster
}

Write-Host "Please enter the Cluster to lookup CISCO FNIC & ENIC Drivers:" -ForegroundColor Yellow -NoNewline
$VMcluster = Read-Host



################# Enabling SSH ######################
Write-Host "Do you need to Enable SSH on the Cluster ESXi Hosts? " -ForegroundColor Yellow -NoNewline
Write-Host " Y/N:" -ForegroundColor Red -NoNewline
$SSHEnable = Read-Host

if ($SSHEnable -eq "y") {


Write-Host "Enabling SSH on all hosts in your specified cluster:" -ForegroundColor Green
Get-Cluster $VMcluster | Get-VMHost | ForEach {Start-VMHostService -HostService ($_ | Get-VMHostService | Where {$_.Key -eq "TSM-SSH"})}

}



################### Confirm Driver Versions #######################


Write-Host "Confirm CISCO FNIC & ENIC Drivers" -ForegroundColor Green
$hosts = Get-Cluster $VMcluster | Get-VMHost
forEach ($vihost in $hosts)
{
Write-Host -ForegroundColor Magenta "Gathering Driver versions on" $vihost
$esxcli = get-vmhost $vihost | Get-EsxCli
$esxcli.software.vib.list() | Where { $_.Name -like "net-enic"} | Select @{N="VMHost";E={$ESXCLI.VMHost}}, Name, Version
$esxcli.software.vib.list() | Where { $_.Name -like "scsi-fnic"} | Select @{N="VMHost";E={$ESXCLI.VMHost}}, Name, Version
}


################### Disabling SSH #######################
Write-Host "Ready to Disable SSH? " -ForegroundColor Yellow -NoNewline
Write-Host " Y/N:" -ForegroundColor Red -NoNewline
$SSHDisable = Read-Host

if ($SSHDisable -eq "y") {


Write-Host "Disabling SSH" -ForegroundColor Green
Get-Cluster $VMcluster | Get-VMHost | ForEach {Stop-VMHostService -HostService ($_ | Get-VMHostService | Where {$_.Key -eq "TSM-SSH"}) -Confirm:$FALSE}

}


