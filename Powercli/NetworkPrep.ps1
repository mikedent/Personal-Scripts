$viserver = "wtzvdvc01.alarm01.local"
 $cluster = "WTZ"
 $vSwitch = "vSwitch0"
 $PGName = "CST DR CAD (VLAN 720)"
 $PGVLANID = "720"
 

Connect-VIserver $viserver -User 'administrator@vsphere.local' -Password 'G/J(yoastJ3c'
 $vmhosts = Get-Cluster $cluster | Get-VMhost

 ForEach ($vmhost in $vmhosts)
 {
 Get-VirtualSwitch -VMhost $vmhost -Name $vSwitch | New-VirtualPortGroup -Name $PGName -VlanId $PGVLANID
 }
