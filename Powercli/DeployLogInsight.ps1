﻿# Deployment of vRealize Operations Manager 6.0 (vROps)
### NOTE: SSH can not be enabled because hidden properties do not seem to be implemented in Get-OvfConfiguration cmdlet ###

# vCenter Connectivity
$VIServer = '172.19.52.2'
$User = 'administrator@vsphere.local'
$Pass = '8zMGBHPb#'


# Load OVF/OVA configuration into a variable
$ovffile = 'E:\TriTech Install Files\VMware\vRealize\VMware-vRealize-Log-Insight-3.6.0-4202923.ova'
$ovfConfiguration = Get-OvfConfiguration -Ovf $ovffile

# Deployment Size Configuration: xsmall,small,medium,large,smallrc,largerc
$size = 'xsmall'

# Disk Format Configuration:  
$DiskFormat = 'Thin'

# vSphere Cluster and Host Configuration
$Cluster = Get-Cluster
$VMHost = Get-Cluster -Name $Cluster |
Get-VMHost |
Sort-Object -Property MemoryGB |
Select-Object -First 1
Get-VMHost |
Sort-Object -Property MemoryGB |
Select-Object -First 1
$ApplianceName = 'ECSVMLOG01'
$VMName = 'ECSVMLOG01.ecscad.local'
$datastore = 'ECSCAD_MGMT_LUN'

# vSphere Portgroup Network Mapping
$VMNetwork = 'CAD Servers'

# IP Address
$ipaddr0 = '172.19.52.4'
$netmask0 = '255.255.255.0'
$gateway = '172.19.52.1'
$dnsServer = '172.19.52.254'
$domainSearch = 'ecscad.local'
$domain = 'ecscad.local'

# Appliance password
$password = '8zMGBHPb#'

# OVF Configuration Parameters
$ovfConfiguration.DeploymentOption.value = $size
$ovfConfiguration.NetworkMapping.Network_1.value = $VMNetwork
$ovfConfiguration.vami.VMware_vCenter_Log_Insight.ip0.Value = $ipaddr0
$ovfConfiguration.vami.VMware_vCenter_Log_Insight.netmask0.Value = $netmask0
$ovfConfiguration.vami.VMware_vCenter_Log_Insight.gateway.Value = $gateway
$ovfConfiguration.vami.VMware_vCenter_Log_Insight.hostname.Value = $VMName
$ovfConfiguration.vami.VMware_vCenter_Log_Insight.DNS.Value = $dnsServer
$ovfConfiguration.vami.VMware_vCenter_Log_Insight.searchpath.Value = $domainSearch
$ovfConfiguration.vami.VMware_vCenter_Log_Insight.searchpath.Value = $domain
$ovfConfiguration.vm.rootpw.value = $password

# Connect to vCenter Instance
Connect-VIServer -Server $VIServer  -User $User -Password $Pass


# Deploy the OVF/OVA with the config parameters
Import-VApp -Source $ovffile -OvfConfiguration $ovfConfiguration -VMHost $VMHost -Datastore $datastore -DiskStorageFormat $DiskFormat -Name $ApplianceName 

Disconnect-VIServer -Server *