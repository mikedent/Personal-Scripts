$vmhost = Get-VMHost labesxi-n3.etherbacon.net
$esxcli= Get-EsxCli -VMHost $vmhost

# First puts the ESX host into maintenance mode...
write-host "Entering Maintenance Mode"
$vmhost | Set-VMHost -State maintenance



#adding new portgroup for vmkernel traffic

$vmhost | Get-VirtualSwitch -Name "vSwitch0" | New-VirtualPortGroup "vmk_vmotion1" -VLanId 110
$vmhost | Get-VirtualSwitch -Name "vSwitch0" | New-VirtualPortGroup "vmk_vmotion2" -VLanId 110
$vmhost | Get-VirtualSwitch -Name "vSwitch0" | New-VirtualPortGroup "vmk_ISCSI" -VLanId 100
$vmhost | Get-VirtualPortGroup -Name "VM Network" | Remove-VirtualPortGroup

# Enable Software iSCSI Adapter on each host
Get-VMHostStorage -VMHost $vmhost | Set-VMHostStorage -SoftwareIScsiEnabled:$true
$vmhost | Get-VirtualPortGroup -name "vmk_ISCSI" | Get-NicTeamingPolicy | Set-NicTeamingPolicy -MakeNicActive "vmnic1"


#adding new network stack
$esxcli.network.ip.netstack.add($false, "vmotion")

#adding new vmkernel interface to new stack
$esxcli.network.ip.interface.add($null, $null, "vmk1", $null, $null, "vmotion", "vmk_vmotion1")
$esxcli.network.ip.interface.add($null, $null, "vmk2", $null, $null, "vmotion", "vmk_vmotion2")
$esxcli.network.ip.interface.add($null, $null, "vmk3", $null, $null, $null, "vmk_ISCSI")

#configuring vmk1 to use dhcp
$esxcli.network.ip.interface.ipv4.set($null, "vmk1", "10.255.255.22", "255.255.255.0", $null, "static")
$esxcli.network.ip.interface.ipv4.set($null, "vmk2", "10.255.255.122", "255.255.255.0", $null, "static")
$esxcli.network.ip.interface.ipv4.set($null, "vmk3", "10.255.250.22", "255.255.255.0", $null, "static")


$vmhba = $vmhost | Get-VMHostHba -Type iScsi | Where {$_.Model -eq "iSCSI Software Adapter"}
$esxcli.iscsi.networkportal.add($vmhba, $false, "vmk3")
New-IScsiHbaTarget -IScsiHba $vmhba -Address "10.255.250.2"
$vmhost | Get-VMHostStorage -RescanAllHba

write-host "Leaving Maintenance Mode"
$vmhost | Set-VMHost -State Connected