Connect-VIServer 10.10.225.22 -User root -Password "Tr!t3cH1"
#get-cluster CAD | 
Get-VMHost | Get-VirtualSwitch -Name vSwitch0 | New-VirtualPortGroup -Name 'DR-CAD-SERVERS-VLAN226' -VLanId 226
Get-VMHost | Get-VirtualSwitch -Name vSwitch0 | New-VirtualPortGroup -Name 'DR-VM-MGMT-VLAN225' -VLanId 225
#>Get-VirtualSwitch -name vSwitch0 | Set-VirtualSwitch -Nic vmnic128, vmnic129
Disconnect-VIServer -Server * -Confirm:$false