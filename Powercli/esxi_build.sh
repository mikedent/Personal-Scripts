# Variables
#########################################
# Change the following:
#
HOSTNAME=ciqhost3
NETMASK=255.255.252.0
VMOTIONA_ADDRESS=10.105.17.3
VMOTIONB_ADDRESS=10.105.17.30
ISCSIA_ADDRESS=10.105.9.3
ISCSIB_ADDRESS=10.105.13.3
VMOTION_VLAN=5
ISCSIA_VLAN=3
ISCSIB_VLAN=4
VM_VLAN=2
#########################################

# Disable IPv6 if desired (Requires Reboot)
esxcli system module parameters set -m tcpip4 -p ipv6=0

# Add vswitch
esxcli network vswitch standard add --ports 128 --vswitch-name vSwitch1
esxcli network vswitch standard add --ports 128 --vswitch-name vSwitch2
esxcli network vswitch standard add --ports 128 --vswitch-name vSwitch3

# Skip if not going to be using Jumbo Frames
esxcfg-vswitch -m 9000 vSwitch1
esxcfg-vswitch -m 9000 vSwitch2
esxcfg-vswitch -m 9000 vSwitch3

# Add NIC
esxcli network vswitch standard uplink add --uplink-name vmnic1 --vswitch-name vSwitch0
esxcli network vswitch standard uplink add --uplink-name vmnic2 --vswitch-name vSwitch1
esxcli network vswitch standard uplink add --uplink-name vmnic3 --vswitch-name vSwitch1
esxcli network vswitch standard uplink add --uplink-name vmnic4 --vswitch-name vSwitch2
esxcli network vswitch standard uplink add --uplink-name vmnic5 --vswitch-name vSwitch2
esxcli network vswitch standard uplink add --uplink-name vmnic6 --vswitch-name vSwitch3
esxcli network vswitch standard uplink add --uplink-name vmnic7 --vswitch-name vSwitch3

# Add Port Groups
esxcli network vswitch standard portgroup add --portgroup-name "vMotion-B" --vswitch-name vSwitch1
esxcli network vswitch standard portgroup set --portgroup-name "vMotion-B" --vlan-id ${VMOTION_VLAN}
esxcli network vswitch standard portgroup add --portgroup-name "vMotion-A" --vswitch-name vSwitch1
esxcli network vswitch standard portgroup set --portgroup-name "vMotion-A" --vlan-id ${VMOTION_VLAN}
esxcli network vswitch standard portgroup add --portgroup-name "iSCSI-B" --vswitch-name vSwitch2
esxcli network vswitch standard portgroup set --portgroup-name "iSCSI-B" --vlan-id ${ISCSIB_VLAN}
esxcli network vswitch standard portgroup add --portgroup-name "iSCSI-A" --vswitch-name vSwitch2
esxcli network vswitch standard portgroup set --portgroup-name "iSCSI-A" --vlan-id ${ISCSIA_VLAN}
esxcli network vswitch standard portgroup add --portgroup-name "Data" --vswitch-name vSwitch3
esxcli network vswitch standard portgroup set --portgroup-name "Data" --vlan-id ${VM_VLAN}
esxcli network vswitch standard portgroup add --portgroup-name "VMMGMT" --vswitch-name vSwitch3
esxcli network vswitch standard portgroup set --portgroup-name "VMMGMT" --vlan-id 6
esxcli network vswitch standard portgroup add --portgroup-name "DataVault" --vswitch-name vSwitch3
esxcli network vswitch standard portgroup set --portgroup-name "DataVault" --vlan-id 8

# Configure vSwitch0 - Management
esxcli network vswitch standard set --cdp-status both --vswitch-name vSwitch0
esxcli network vswitch standard policy failover set --active-uplinks vmnic0,vmnic1 --vswitch-name vSwitch0
esxcli network vswitch standard portgroup remove -p "VM Network" -v vSwitch0

# Configure vSwitch1 - vMotion
esxcli network vswitch standard policy failover set --active-uplinks vmnic2,vmnic3 --vswitch-name vSwitch1
esxcli network ip interface add --interface-name vmk1 --portgroup-name vMotion-A
esxcli network ip interface add --interface-name vmk2 --portgroup-name vMotion-B
vim-cmd hostsvc/vmotion/vnic_set vmk1
vim-cmd hostsvc/vmotion/vnic_set vmk2
esxcli network ip interface ipv4 set --interface-name vmk1 --ipv4 ${VMOTIONA_ADDRESS} --netmask ${NETMASK} --type static
esxcli network ip interface ipv4 set --interface-name vmk2 --ipv4 ${VMOTIONB_ADDRESS} --netmask ${NETMASK} --type static
esxcli network ip interface set -m 9000 -i vmk1 # Skip if not using Jumbo Frames
esxcli network ip interface set -m 9000 -i vmk2 # Skip if not using Jumbo Frames

# Enable iSCSI Adapter
esxcli iscsi software set --enabled=true
ADAPTER=`esxcli iscsi adapter list | grep Software | awk '{print $1;}'`
esxcli iscsi adapter set -A ${ADAPTER} --name iqn.1998-01.com.vmware:${HOSTNAME}

# Configure vSwitch2 - iSCSI
esxcli network vswitch standard policy failover set --active-uplinks vmnic4,vmnic5 --vswitch-name vSwitch2
esxcli network ip interface add --interface-name vmk3 --portgroup-name iSCSI-A
esxcli network ip interface add --interface-name vmk4 --portgroup-name iSCSI-B
esxcli network vswitch standard portgroup policy failover set --active-uplinks=vmnic4 --portgroup-name=iSCSI-A
esxcli network vswitch standard portgroup policy failover set --active-uplinks=vmnic5 --portgroup-name=iSCSI-B

esxcli network ip interface ipv4 set --interface-name vmk3 --ipv4 ${ISCSIA_ADDRESS} --netmask ${NETMASK} --type static
esxcli network ip interface ipv4 set --interface-name vmk4 --ipv4 ${ISCSIB_ADDRESS} --netmask ${NETMASK} --type static
esxcli network ip interface set -m 9000 -i vmk3 # Skip if not using Jumbo Frames
esxcli network ip interface set -m 9000 -i vmk4 # Skip if not using Jumbo Frames

# Configure vSwitch3 - VM Network
esxcli network vswitch standard policy failover set --active-uplinks vmnic6,vmnic7 --vswitch-name vSwitch3
