$viserver = "172.30.79.35"
#$cluster = "WTZ"
$vSwitch = "vSwitch0"
$PGName = "VM-Management (VLAN 2343)"
$PGVLANID = "2343"
$PGName1 = "CAD (VLAN 2344)"
$PGVLANID1 = "2344"
$PGName2 = "RMS (VLAN 2345)"
$PGVLANID2 = "2345"
$PGName3 = "CVM (Untagged)"
$PGVLANID3 = "0"
 

Connect-VIserver $viserver -User 'root' -Password 'nutanix/4u'
#$vmhosts = Get-Cluster $cluster | Get-VMhost
$vmhosts = Get-VMHost

ForEach ($vmhost in $vmhosts) {
    Get-VirtualSwitch -VMhost $vmhost -Name $vSwitch | New-VirtualPortGroup -Name $PGName -VlanId $PGVLANID
    Get-VirtualSwitch -VMhost $vmhost -Name $vSwitch | New-VirtualPortGroup -Name $PGName1 -VlanId $PGVLANID1
    Get-VirtualSwitch -VMhost $vmhost -Name $vSwitch | New-VirtualPortGroup -Name $PGName2 -VlanId $PGVLANID2
    Get-VirtualSwitch -VMhost $vmhost -Name $vSwitch | New-VirtualPortGroup -Name $PGName3 -VlanId $PGVLANID3
}
