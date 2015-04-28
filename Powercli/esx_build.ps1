# ESXi Build PowerShell Script (Specific to TriTech CAD)
# By Mike Dent
# Date 4/7/2015
#
# Set Variables to be used in the ESXi Host configuration
# Modify these settings for your requirements
#
# The script does the following:
# 1. Captures variables specific to the host environment
# 2. Authentiates to the host and places in maintenance mode


## Begin Static Variables ##
# NTP Time Servers to use
	$ntp = @("10.200.50.61")

# DNS Search Details to use
	$DomainName = "host.dns.doman.name"
	$DNSSearch = "host.dns.search.name"
	$PreferredDNS = "x.x.x.x"
	$AltDNS = "x.x.x.x"

# ESXi Host NICS
	$vmnic = @("vmnic0","vmnic1","vmnic2","vmnic3","vmnic4","vmnic5") #Array of ESXi host's vmnics

# These NICs are connected to the management network vSwitch0
	$esxnics = "vmnic0","vmnic2","vmnic3","vmnic5"

# This/these NICs are connected to the VM network vSwitch1
#	$vmotionnics = "vmnic2","vmnic3"

# This/these NICs are connected to the VM network vSwitch2
	$iscsinics = "vmnic1","vmnic4"

# This/these NICs are connected to the VM network vSwitch3
#	$vmnics = "vmnic2","vmnic3"

# VMotion Subnet Mask
	$VMotionSubnet = "255.255.255.0"

# iSCSI Subnet Mask
	$IscsiSubnetMask = "255.255.255.0"

# Host Licensing
$License = "JN421-4730P-L8Q4X-0J9HH-A9940"


# vmkernel Numbers
	$vmknumber = @("vmk2","vmk3")

## End Static Variables ##

## Begin Dynamic Variables ##
Write-Host "ESXi Configuration script for VMware ESXi Hosts for CAD Servers"

# Capture unique variables for the ESXi Host by user input
	$HostPassword=Read-Host "Enter the password to the root account on the ESXi Host"

	$EnableSsh=Read-Host "Enable SSH? (1 for Yes, 0 for No)"
	$DisableIpv6 = Read-Host "Disable IPv6 System Wide? (1 for Yes, 0 for No)"
	$EnableReboot = Read-Host "Woudl you like to reboot at the end of this script? (1 for Yes, 0 for No)"

	$vMotionVlan = Read-Host "Enter the vMotion VLAN (0 if not trunked)"
	$iScsiAvLan = Read-Host "Enter the number of the ISCSI A VLAN (0 if not trunked)"
	$iScsiBvLan = Read-Host "Enter the number of the ISCSI B VLAN (0 if not trunked)"

	$DataName = Read-Host "Enter the CAD Network name"
	$DataVLAN = Read-Host "Enter the VLAN for the CAD Network"
## End Dynamic Variables ##

Import-CSV vmhosts.csv | ForEach-Object {
		$vmhost = $_.vmhost
		$vMotionIp = $_.vmotionip
		$iScsiAiP = $_.iscsiaip
		$iScsiBiP = $_.iscsibip

	# Authenticate to ESX Host...
		write-host "Connecting to " $vmhost
		$esxhost = Connect-VIServer $vmhost -User root -Password $HostPassword

	# Sets up PowerCLI to be able to access esxcli commands
		$esxcli = Get-EsxCli

	# First puts the ESX host into maintenance mode...
		write-host "Entering Maintenance Mode"
		Set-VMHost -State maintenance

  # Disable IPV6 System Wide

		if ("1" -eq $DisableIpv6){
			Write-Host "Disabling IPv6 System Wide"
			Get-VMHostModule -Name "tcpip4" | Set-VMHostModule -Options "ipv6=0"
		}


	# Configure vSwitch0
		write-host "Configuring vSwitch0"
		$vs0 = Get-VirtualSwitch -Name vSwitch0
		#Set-VirtualSwitch -VirtualSwitch $vs0 -Nic $esxnics -Confirm:$false
		#Add-VirtualSwitchPhysicalNetworkAdapter -VirtualSwitch $vs0 -VMHostPhysicalNic $vmnic[0]
		#Add vmnic1,vmnic2,vmnic3 to vSwitch0
		Add-VirtualSwitchPhysicalNetworkAdapter -VirtualSwitch $vs0 -VMHostPhysicalNic (Get-VMHostNetworkAdapter -Physical -Name $vmnic[2],$vmnic[3],$vmnic[5]) -Confirm:$false
		Get-VirtualPortGroup -name "Management Network" | Get-NicTeamingPolicy | Set-NicTeamingPolicy -MakeNicActive $vmnic[0]
		Get-VirtualPortGroup -name "Management Network" | Get-NicTeamingPolicy | Set-NicTeamingPolicy -MakeNicStandby $vmnic[2]
		Get-VirtualPortGroup -name "Management Network" | Get-NicTeamingPolicy | Set-NicTeamingPolicy -MakeNicUnused $vmnic[3],$vmnic[5]

	# Configure vMotion
		New-VirtualPortGroup -Name vMotion -VirtualSwitch $vs0 -VLanId $VmotionVlan
		New-VMHostNetworkAdapter -PortGroup vMotion -VirtualSwitch $vs0 -IP $VMotionIP -SubnetMask $VMotionSubnet -VMotionEnabled: $true
		Get-VirtualPortGroup -name "vMotion" | Get-NicTeamingPolicy | Set-NicTeamingPolicy -MakeNicActive $vmnic[2]
		Get-VirtualPortGroup -name "vMotion" | Get-NicTeamingPolicy | Set-NicTeamingPolicy -MakeNicStandby $vmnic[0]
		Get-VirtualPortGroup -name "vMotion" | Get-NicTeamingPolicy | Set-NicTeamingPolicy -MakeNicUnused $vmnic[3],$vmnic[5]

	# Removes "VM Network" from the vSwitch0 and Creates a new VM Network
		get-VirtualPortGroup  | where { $_.Name -like "VM Network"} |  Remove-VirtualPortGroup  -Confirm:$false
		New-VirtualPortGroup -VirtualSwitch $vs0 -name $DataName -VLanId $DataVlan
		Get-VirtualPortGroup -name $DataName | Get-NicTeamingPolicy | Set-NicTeamingPolicy -MakeNicActive $vmnic[0],$vmnic[3],$vmnic[5]
		Get-VirtualPortGroup -name $DataName | Get-NicTeamingPolicy | Set-NicTeamingPolicy -MakeNicStandby $vmnic[2]

	# Configure vSwitch1
		write-host "Configuring vSwitch1"
		$vs1 = New-VirtualSwitch -Name vSwitch1
		Add-VirtualSwitchPhysicalNetworkAdapter -VirtualSwitch $vs1 -VMHostPhysicalNic (Get-VMHostNetworkAdapter -Physical -Name $vmnic[1],$vmnic[4]) -Confirm:$false
		write-host "Configuring " $iSCSIAName "Port Group"
		New-VirtualPortGroup -VirtualSwitch $vs1 -Name $ISCSIAName -VLanId $ISCSIAVLAN
		write-host "Configuring " $ISCSIBName "Port Group"
		New-VirtualPortGroup -VirtualSwitch $vs1 -Name $ISCSIBName -VLanId $ISCSIBVLAN
		New-VMHostNetworkAdapter  -PortGroup ISCSI-A -VirtualSwitch $vs1 -IP $IscsiAiP -SubnetMask $IscsiSubnetMask -VMotionEnabled: $false
		Get-VirtualPortGroup -name $iSCSIAName | Get-NicTeamingPolicy | Set-NicTeamingPolicy -MakeNicActive $vmnic[1]
		Get-VirtualPortGroup -name $iSCSIAName | Get-NicTeamingPolicy | Set-NicTeamingPolicy -MakeNicUnused $vmnic[4]
		New-VMHostNetworkAdapter  -PortGroup ISCSI-B -VirtualSwitch $vs1 -IP $IscsiBiP -SubnetMask $IscsiSubnetMask -VMotionEnabled: $false
		Get-VirtualPortGroup -name $iSCSIBName | Get-NicTeamingPolicy | Set-NicTeamingPolicy -MakeNicActive $vmnic[4]
		Get-VirtualPortGroup -name $iSCSIBName | Get-NicTeamingPolicy | Set-NicTeamingPolicy -MakeNicUnused $vmnic[1]

	# Enable Software iSCSI Adapter on each host
	  #Write-Host "Enabling Software iSCSI Adapter on " $vmhost
		#$h = Get-VMHost | Get-View -Property "ConfigManager.StorageSystem"
		#$hostStorageSystem = Get-view $h.ConfigManager.StorageSystem
		#$hostStorageSystem.UpdateSoftwareInternetScsiEnabled($true)
		Get-VMHostStorage -VMHost $vmhost | Set-VMHostStorage -SoftwareIScsiEnabled:$true

	# Just a sleep to wait for the adapter to load
		Write-Host "Sleeping for 10 Seconds..." -ForegroundColor Green
		Start-Sleep -Seconds 10
		Write-Host "OK Here we go..." -ForegroundColor Green

	# Collects the vmk interfaces for the iSCSI Software Adapter we'll add later
		$portname = Get-VMHostNetworkAdapter | where {$_.PortGroupName -match "ISCSI-*"} | %{$_.DeviceName}

	# Binds VMKernel ports to the iSCSI Software Adapter HBA
		Write-Host "Binding ISCSI vmk interfaces to Adapter"
		$vmhba = Get-VMHostHba -VMHost $vmhost -Type iscsi | %{$_.Device}
		$esxcli.iscsi.networkportal.add($vmhba, $false, $portname[0]) #Bind vmk2
		$esxcli.iscsi.networkportal.add($vmhba, $false, $portname[1]) #Bind vmk3


	# Configure vSwitch Security for all vSwitches
		write-host "Configuring vSwitch Security settings and enabling Beacon Probing for all vSwitches"
		#Reject MAC Address Changes and Forged Transmits on VM Portgroup
		#EsxCLI command synthax: network vswitch standard portgroup policy security set --allow-forged-transmits --allow-mac-change --allow-promiscuous --portgroup-name --use-vswitch
		$esxcli.network.vswitch.standard.portgroup.policy.security.set($false, $false, $false, $DataName, $false)

	# Set-up the NTP Configuration
		write-host "Adding NTP Servers"
		Add-VmHostNtpServer -NtpServer $ntp[0], $ntp[1] -Confirm:$false
		Get-VMHostService | where-Object {$_.Key -eq "ntpd"} | Set-VMHostService -Policy Automatic
		Get-VmhostFirewallException -VMHost $ESX -Name "NTP Client" | Set-VMHostFirewallException -enabled:$true
		a

	# Set DNS Details to ensure they have been set
		#	write-host "Resetting DNS Details"
		#	$vmHostNetworkInfo = Get-VmHostNetwork -VMHost $vmhost
		#	Set-VmHostNetwork -Network $vmHostNetworkInfo -DomainName $DomainName -SearchDomain $DNSSearch
		#	Set-VmHostNetwork -Network $vmHostNetworkInfo -DnsAddress $PreferredDNS, $AltDNS

	# Rename Local Datastore
		#	$LocalName = $vmhost.ToUpper()
		#	Get-Datastore -Name "datastore1" | Set-Datastore -Name $LocalName"-LOCAL"

	# Enable/Disable SSH
		if ("1" -eq $EnableSsh) {
			Write-Host "The SSH Service will be set to start when the hosts boots"
			Get-VMHostService | where {$_.Key -eq "TSM-SSH"} | Set-VMHostService -Policy On
			Get-VMHostService | where {$_.Key -eq "TSM-SSH"} | Start-VMHostService
			Get-AdvancedSetting -Entity (Get-VMHost) -Name "UserVars.SuppressShellWarning" | Set-AdvancedSetting -Value 1 -Confirm:$false }
		Else {
			Write-Host "The SSH Service will remain disabled" }

	# Licensing ESXi Host
		$licMgr = Get-View -Id 'LicenseManager-ha-license-manager'
		$licMgr.UpdateLicense($License, $null)

	# Restart the ESXi Host
		if ("1" -eq $EnableReboot) {
			Write-Host "Script Complete..." -ForegroundColor Green
			Write-Host "Initiating Host Reboot in 10 seconds..." -ForegroundColor Green
			Start-Sleep -Seconds 10
			Restart-VMHost -server $vmhost -confirm:$false }
		else {
			Write-Host "Script Complete"
		# Provide Post config Instructions
			write-host "The basic ESXi Host configuration is completed, please:"
			write-host "1. Reboot hosts when possible."
			write-host "2. Verify the Host Configuration is correct"
			write-host "3. Confirm all patches have been applied (scan for updates)"
			Write-Host "4. Once complete take the ESXi host out of Maintenance Mode"
		}


	# Disconnect from ESXi Host
		Disconnect-VIServer -Confirm:$False

}
