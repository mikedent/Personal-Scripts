#requires -Version 1.0

# Deployment of vRealize Operations Manager 6.0 (vROps)
### NOTE: SSH can not be enabled because hidden properties do not seem to be implemented in Get-OvfConfiguration cmdlet ###

# vCenter Connectivity
$VIServer = '10.10.201.2'
$User = 'administrator@vsphere.local'
$Pass = 'G0lden*ak'


# Load OVF/OVA configuration into a variable
$ovffile = 'Z:\Albany Install Files\VMware\VMware-vRealize-Log-Insight-3.3.2-3951163.ova'
$ovfConfiguration = Get-OvfConfiguration -Ovf $ovffile

# Deployment Size Configuration: xsmall,small,medium,large,smallrc,largerc
$size = 'xsmall'

# Disk Format Configuration:  
$DiskFormat = 'Thin'

# vSphere Cluster and Host Configuration
$Cluster = 'Compute'
$VMHost = Get-Cluster $Cluster |
Get-VMHost |
Sort-Object -Property MemoryGB |
Select-Object -First 1
$ApplianceName = 'LogInsight'
$VMName = 'loginsight.etherbacon.net'
$datastore = 'Servers'

# vSphere Portgroup Network Mapping
$VMNetwork = 'vxw-dvs-45-virtualwire-3-sid-5001-vRealizeAppliances'

# IP Address
$ipaddr0 = '10.200.0.12'
$netmask0 = '255.255.255.0'
$gateway = '10.200.0.1'
$dnsServer = '10.10.200.254'
$domainSearch = 'etherbacon.net'
$domain = 'etherbacon.net'

# Appliance password
$password = 'G0lden*ak'

# OVF Configuration Parameters
$ovfConfiguration.DeploymentOption.value = $size
$ovfConfiguration.NetworkMapping.Network_1.value = $VMNetwork
$ovfConfiguration.vami.VMware_vCenter_Log_Insight.ip0.Value = $ipaddr0
$ovfConfiguration.vami.VMware_vCenter_Log_Insight.netmask0.Value = $netmask0
$ovfConfiguration.vami.VMware_vCenter_Log_Insight.gateway.Value = $gateway
$ovfConfiguration.vami.VMware_vCenter_Log_Insight.hostname.Value =  $VMName
$ovfConfiguration.vami.VMware_vCenter_Log_Insight.DNS.Value = $dnsServer
$ovfConfiguration.vami.VMware_vCenter_Log_Insight.searchpath.Value = $domainSearch
$ovfConfiguration.vami.VMware_vCenter_Log_Insight.searchpath.Value = $domain
$ovfConfiguration.vm.rootpw.value = $password

# Connect to vCenter Instance
Connect-VIServer -Server $VIServer  -User $User -Password $Pass


# Deploy the OVF/OVA with the config parameters
Import-VApp -Source $ovffile -OvfConfiguration $ovfConfiguration -VMHost $VMHost -Datastore $datastore -DiskStorageFormat $DiskFormat -Name $ApplianceName

disconnect-viserver *