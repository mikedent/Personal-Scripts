#requires -Version 1.0

$path = 'Z:\Albany Install Files\VMware\VMware-vRealize-Log-Insight-3.3.2-3951163.ova'
$size = 'Extra Small'
$vmAdapter = 'VM Management'
$ipaddr0 = '10.91.0.183'
$netmask0 = '255.255.255.128'
$gateway = '10.91.0.129'
$hostname = 'acsovmlog01.e911.local'
$dnsserv = '10.91.0.250'
$password = 'Tr!t3cH1'
$name = 'ACSOVMLOG01'
$location = 'Resources'
$vmhost = 'acsovmhost01.e911.local'
$datastore = 'ACSO_MGMT_LUN_10'
$ovfConfiguration = Get-OvfConfiguration -Ovf $path
$ovfConfiguration.DeploymentOptions.Value = $size
$ovfConfiguration.NetworkMapping.Network_1.Value = $vmAdapter
$ovfConfiguration.vami.VMware_vCenter_Log_Insight.ip0.Value = $ipaddr0
$ovfConfiguration.vami.VMware_vCenter_Log_Insight.netmask0.Value = $netmask0
$ovfConfiguration.vami.VMware_vCenter_Log_Insight.gateway.Value = $gateway
$ovfConfiguration.vami.VMware_vCenter_Log_Insight.hostname.Value = $hostname
$ovfConfiguration.vami.VMware_vCenter_Log_Insight.DNS.Value = $dnsserv
$ovfConfiguration.vm.rootpw.Value = $password
Connect-VIServer -Server acsovmvct01.e911.local -User administrator@vsphere.local -Password Tr!t3cH1

Import-VApp -Source $path -OvfConfiguration $ovfConfiguration -Name $name -Location $location -VMHost $vmhost -Datastore $datastore -DiskStorageFormat Thin