https://connect.nimblestorage.com/thread/2420
http://blog.allford.id.au/2016/powercli-script-configure-esxi-host-for-connectivity-to-nimble-iscsi-san/



<#
.Synopsis
   Configures an ESXi host with a new vSwitch and configures the iSCSI Software Adapter to connect to Nimble Storage

.DESCRIPTION
   This script can fully configure an ESXi host following the Nimble Storage best practice and guidelines to connect the ESXi host to Nimble Storage Array(s).
   You will be required to speficy two vmnic uplink adapters to bind to the switch, as well as two IP addresses to bind to the vmkernel ports.
   This script will only configure the iSCSI Software Adapter on the ESXi host. This script modifies some of the advanced settings of the iSCSI Software Adapter,
   to align with Nimble Storage best practices. If the Software Adapter is in use for connectivity to other devices in the environment, ensure the changes made in
   this script will not conflict.

.EXAMPLE
   Create-NimbleVSwitch -Hostname ESXi1 -Uplink1 vmnic1 -Uplink2 vmnic2 -vSwitchName iSCSIVSwitch -PortGroup1Name iSCSIPG1 -PortGroup2Name iSCSIPG2 -iSCSIAddress1 192.168.0.10 -iSCSIAddress2 192.168.0.11 -iSCSITargetAddress 192.168.0.250 -iSCSIVLAN 800 -MTU 9000 -RebootHost $True
   This command will create a vSwitch on host ESXi1, bind vmnic1 and vmnic2 to the switch, create two new port groups names iSCSIPG1/iSCSIPG2, create two VMKernel adapters with the IP addresses 192.168.0.10 and 192.168.0.11 that are associated with the two new port groups.
   The portgroups will be tagged with VLAN 800 and the MTU of 9000 will be configured in the relevant spots on the ESXi host. If the iSCSI software intiiator is not installed, it will get installed, the two new vmkernel adapters will be added to the software initiator and the iSCSI Target IP address will be added as a target on the software initiator
   The host will reboot after the changes have been applied.

.PARAMETER HostMaintenanceMode
    Places the host into maintenance mode before making any configuration changes

.PARAMETER Hostname
    The Name of the ESXi Host to configure

.PARAMETER Uplink1
    The Name of the first vmnic uplink to bind to the vSwitch, ie vmnic1

.PARAMETER Uplink2
    The Name of the second vmnic uplink to bind to the vSwitch, ie vmnic2

.PARAMETER vSwitchName
    The Name of the new vSwitch that will be created. If not specified, the switch will be named vSwitchiSCSI-Nimble

.PARAMETER PortGroup1Name
    The Name of the first portgroup to be created on the new vSwitch. If not specified, the portgroup will be named iSCSI-Nimble1

.PARAMETER PortGroup1Name
    The Name of the second portgroup to be created on the new vSwitch. If not specified, the portgroup will be named iSCSI-Nimble2

.PARAMETER iSCSIIP1
    The first IP address that will be bound to the first new vmkernel adapter on the ESXi host

.PARAMETER iSCSIIP2
    The second IP address that will be bound to the second new vmkernel adapter on the ESXi host

.PARAMETER iSCSITargetAddress
    The Nimble array discovery IP address. This will be added as a target address on the iSCSI software adapter on the ESXi host

.PARAMETER iSCSIVLAN
    The VLAN ID for iSCSI traffic. This VLAN ID will be set on the new portgroups. This paramater is optional and depends on your environment

.PARAMETER MTU
    Enter the MTU to be used in the configuration on the ESXi host

.PARAMETER RebootHost
    Determines whether the ESXi host will be rebooted after all config is complete

.LINK
http://blog.allford.id.au/2016/powercli-function-configure-esxi-host-for-connectivity-to-nimble-iscsi-san

.NOTES
Written By: Matt Allford
Website:	http://blog.allford.id.au
Twitter:	http://twitter.com/mattallford

Change Log
V1.00, 30/01/2015 - Initial version
#>

    [CmdletBinding()]

    Param
    (
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        $Hostname,

        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        $Uplink1,

        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        $Uplink2,

        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        $vSwitchName = "vSwitchiSCSI-Nimble",

        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        $PortGroup1Name = "iSCSI-Nimble1",

        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        $PortGroup2Name = "iSCSI-Nimble2",

        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        $iSCSIAddress1,

        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        $iSCSIAddress2,

        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        $iSCSITargetAddress,

        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        $iSCSISubnetMask = "255.255.255.0",

        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [int]$MTU,
        
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]$iSCSIVLAN,

        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [switch]$RebootHost,

        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [switch]$HostMaintenanceMode

    )


    if ($HostMaintenanceMode -eq $True){
        #Place Host in maintenance mode
        $HostConnectionState = Get-VMHost -Name $Hostname

        #Check to see is host is already in maintenance mode. If not, place the host in maintenance mode
        if ($HostConnectionState.ConnectionState -eq "Maintenance"){
        }ELSE{
        Set-VMHost -VMHost $Hostname -State Maintenance
        }
    }

    #Create standard vSwitch on the ESXi host
    $vSwitch = New-VirtualSwitch -VMHost $Hostname -Name $vSwitchName -Mtu $MTU -Nic $Uplink1,$Uplink2

    #Create portgroups on newly created vSwitch
    if ($iSCSIVLAN){
        New-VirtualPortGroup -VirtualSwitch $vSwitch -Name $PortGroup1Name -VLanId $iSCSIVLAN
        New-VirtualPortGroup -VirtualSwitch $vSwitch -Name $PortGroup2Name -VLanId $iSCSIVLAN
        }ELSE{
        New-VirtualPortGroup -VirtualSwitch $vSwitch -Name $PortGroup1Name
        New-VirtualPortGroup -VirtualSwitch $vSwitch -Name $PortGroup2Name
        }

    #Create VMKernel ports for iSCSI traffic on the new portgroups
    $VMKernel1 = New-VMHostNetworkAdapter -VMHost $Hostname -VirtualSwitch $vSwitch -PortGroup $PortGroup1Name -IP $iSCSIAddress1 -SubnetMask $iSCSISubnetMask -Mtu $MTU
    $VMKernel2 = New-VMHostNetworkAdapter -VMHost $Hostname -VirtualSwitch $vSwitch -PortGroup $PortGroup2Name -IP $iSCSIAddress2 -SubnetMask $iSCSISubnetMask -Mtu $MTU

    #Set the Active and Unused uplinks / vmnics
    Get-VirtualPortGroup -VMHost $Hostname -VirtualSwitch $vswitch -Name $PortGroup1Name | Get-NicTeamingPolicy | Set-NicTeamingPolicy -MakeNicActive $Uplink1 -MakeNicUnused $Uplink2
    Get-VirtualPortGroup -VMHost $Hostname -VirtualSwitch $vswitch -Name $PortGroup2Name | Get-NicTeamingPolicy | Set-NicTeamingPolicy -MakeNicActive $Uplink2 -MakeNicUnused $Uplink1


    #Add the Nimble discovery IP as an iSCSI send target to the software adapter
    $hba = Get-VMHostHba -VMHost $Hostname -Type iScsi | Where-Object {$_.Model -eq "iSCSI Software Adapter"}
        
        #Check to see if no adapters were found in the last cmdlet. If there are no results, enable the iSCSI Software Adapter on the ESXi Host
    if (!$hba){
        #Enable the iSCSI Software Adapter
        Get-VMHostStorage $Hostname | Set-VMHostStorage -SoftwareIScsiEnabled $True
        $hba = Get-VMHostHba -VMHost $Hostname -Type iScsi | Where-Object {$_.Model -eq "iSCSI Software Adapter"}
    }

    #If the iSCSI Target Address was provided, add the address to the iSCSI Software Initiator target list
    if ($iSCSITargetAddress){
    New-IScsiHbaTarget -IScsiHba $hba -Address $iSCSITargetAddress
    }

    #Sets up PowerCLI to be able to access esxcli commands
    $esxcli = Get-EsxCli -VMHost $Hostname

    #Binds VMKernel ports created earlier to the iSCSI Software Adapter HBA
    $esxcli.iscsi.networkportal.add($HBA.device,$null,$VMKernel1.Name)
    $esxcli.iscsi.networkportal.add($HBA.device,$null,$VMKernel2.Name)

    #Using esxcli, configure the LoginTimeout, NoopTimeout and NoopInterval values to the Nimble best practice of 30 seconds
    $esxcli.iscsi.adapter.param.set($hba.device,$false,'LoginTimeout','30')
    $esxcli.iscsi.adapter.param.set($hba.device,$false,'NoopOutTimeout','30')
    $esxcli.iscsi.adapter.param.set($hba.device,$false,'NoopOutInterval','30')

    #Restart the host to apply the timeout settings
    if ($RebootHost){
        Restart-VMHost -VMHost $Hostname -Confirm:$false
    }