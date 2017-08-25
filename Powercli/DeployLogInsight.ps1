# Deployment of vRealize Operations Manager 6.0 (vROps)
### NOTE: SSH can not be enabled because hidden properties do not seem to be implemented in Get-OvfConfiguration cmdlet ###

# vCenter Connectivity
$VIServer = '192.168.200.39'
$User = 'administrator@vsphere.local'
$Pass = 'Tr!t3cH1'


# Load OVF/OVA configuration into a variable
$ovffile = "E:\InstallFiles\VMware\vRealize\VMware-vRealize-Log-Insight-4.3.0-5084751.ova"
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
$ApplianceName = 'NCDJPALOG01'
$VMName = 'NCDJPALOG01.ncdjpa.org'
$datastore = 'MGMT_LUN'

# vSphere Portgroup Network Mapping
$VMNetwork = 'CAD Network'

# IP Address
$ipaddr0 = '192.168.200.40'
$netmask0 = '255.255.255.0'
$gateway = '192.168.200.1'
$dnsServer = '192.168.253.218'
$domainSearch = 'ncdjpa.org'
$domain = 'ncdjpra.org'

# Appliance password
$password = 'Tr!t3cH1'

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