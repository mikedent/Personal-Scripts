Connect-VIServer 10.105.144.35 -User root -Password "nutanix/4u"
#get-cluster CAD | 
Get-VMHost | Get-VirtualSwitch -Name vSwitch0 | New-VirtualPortGroup -Name 'VM-Management-VLAN145' -VLanId 145
Get-VMHost | Get-VirtualSwitch -Name vSwitch0 | New-VirtualPortGroup -Name 'CAD-VDI-VLAN147' -VLanId 147
#>Get-VirtualSwitch -name vSwitch0 | Set-VirtualSwitch -Nic vmnic128, vmnic129
Disconnect-VIServer *