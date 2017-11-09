
<#

Author:
Version:
Version History:

Purpose:

#>


$DefaultVIServer = '10.105.141.10'
$vcuser = 'administrator@vsphere.local'
$vcpass = 'E911@dmin!'


  # Connect to vCenter
  Connect-VIServer $DefaultVIServer -user $vcuser -password $vcpass


$portgroups = $(Get-VirtualPortGroup).Name
$hosts = $(Get-VMHost).Name
$datastores = $(Get-Datastore).Name
$resourcepools = $(Get-ResourcePool).Name
$continueflag = "n"

while($continueflag -eq "n"){
   $path = Read-Host "Path to OVA file"
   $ovfConfiguration.DeploymentOptions.Value = Read-Host "$($ovfConfiguration.DeploymentOption.Description) `nDeployment Size?"
   $(Get-VirtualPortGroup).Name
   $ovfConfiguration.NetworkMapping.Network_1.Value = Read-Host "Which Port Group"
   $ovfConfiguration.vami.VMware_vCenter_Log_Insight.ip0.Value = Read-Host "IP Address"
   $ovfConfiguration.vami.VMware_vCenter_Log_Insight.netmask0.Value = Read-Host "Netmask"
   $ovfConfiguration.vami.VMware_vCenter_Log_Insight.gateway.Value = Read-Host "Gateway"
   $ovfConfiguration.vami.VMware_vCenter_Log_Insight.hostname.Value = Read-Host "Hostname"
   $ovfConfiguration.vami.VMware_vCenter_Log_Insight.DNS.Value = Read-Host "DNS Servers - Comma seperated, no spaces"
   $ovfConfiguration.vm.rootpw.Value = Read-Host "Password"
   $(Get-ResourcePool).Name
   $resourcepool = Read-Host "Resource Pool"
   $(Get-VMhost).Name
   $vmhost = Read-Host "VM host"
   $(Get-Datastore).Name
   $datastore = Read-Host "Datastore"

   Write-Host "Please Review the configuration options"
   $ovfConfiguration.ToHashTable() | fl
   Write-Host "Resource Pool - $resourcepool"
   Write-Host "VM Host - $vmhost"
   Write-Host "Datastore - $datastore"
   $continueflag = Read-Host "Is this correct? `'y`' for yes `'n`' for no"
}

Import-VApp -Source $path -OvfConfiguration $ovfConfiguration -Name $name -Location $resourcepool -VMHost $vmhost -Datastore $datastore