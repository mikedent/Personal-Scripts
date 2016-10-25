###########################################################################
# Start of the script - Description, Requirements
###########################################################################
# Author:
# Mike Dent
# Description:
# This script automates the build of a standard ESXi host
################################################ 
# Requirements:
# - ESXi ServerName, Username and password to establish as session using PowerCLI
# - Hostname and Network Parameters for each host
# - Access permission to write in and create (or create it manually and ensure the user has permission to write within)the directory specified for logging
# - VMware PowerCLI, any version, installed on the host running the script
# - Run PowerShell as administrator with command "Set-ExecutionPolcity unrestricted"
################################################

################################################
# Configure host specific variables below
################################################
$VIServer = '10.94.0.25'
$vMotionIP = '10.255.253.25'
$vMotionVlan = '930'
$subnetMask = '255.255.255.0'
$MTU = '9000'
$User = 'root'
$Pass = ''

# Host Configuration Parameters
$DomainName = 'escad.local'
$DNSSearch = 'escad.local'
$PreferredDNS = '8.8.8.8'
#$AltDNS = "x.x.x.x"  TBD
$NTPServers = ('10.255.255.225')
$EnableSsh = 'True'
$HostMaintenanceMode = 'True'
$RebootHost = 'False'
$CADNetworkName = 'CAD Servers'

$License = '4M01L-68L12-68A9W-02386-A82JN'

# Network Parameters
$VmnicInterface = @(
  'vmnic0', 
  'vmnic1', 
  'vmnic2', 
  'vmnic3',
  'vmnic4', 
  'vmnic5', 
  'vmnic6', 
  'vmnic7',
  'vmnic8', 
  'vmnic9'
)
################################################
# End configuration of Variables
################################################

################################################
# Configure Logging
################################################
# Configure Log Directory for logging of activity
$LogDataDir = "$env:HOMEDRIVE\Scripts\LogOutput"

# Setting log directory for engine and current month
$CurrentMonth = Get-Date -Format MM.yy
$CurrentTime = Get-Date -Format hh.mm.ss
$CurrentLogDataDir = $LogDataDir + $CurrentMonth
$CurrentLogDataFile = $LogDataDir + $CurrentMonth + '\ESXIBuild-' + $VIServer + '.txt'
# Testing path exists to engine logging, if not creating it
$ExportDataDirTestPath = Test-Path -Path $CurrentLogDataDir
if ($ExportDataDirTestPath -eq $False)
{
  New-Item -ItemType Directory -Force -Path $CurrentLogDataDir
}
################################################
# End Logging Configuration
################################################

################################################
# Starting ESXi Customization Process
################################################
# Start Logging
Start-Transcript -Path $CurrentLogDataFile -NoClobber
# Connect to vCenter/Host instance
Connect-VIServer -Server $VIServer  -User $User -Password $Pass

# Place host in Maintenace Mode
if ($HostMaintenanceMode -eq $True)
{
  #Place Host in maintenance mode
  $HostConnectionState = Get-VMHost

  #Check to see is host is already in maintenance mode. If not, place the host in maintenance mode
  if ($HostConnectionState.ConnectionState -eq 'Maintenance')
  {

  }
  ELSE
  {
    Set-VMHost -VMHost $Hostname -State Maintenance
  }
}

# Configure Domain and DNS

# Set DNS Details to ensure they have been set
$vmHostNetworkInfo = Get-VMHostNetwork
Set-VMHostNetwork -Network $vmHostNetworkInfo -DomainName $DomainName -SearchDomain $DNSSearch
Set-VMHostNetwork -Network $vmHostNetworkInfo -DnsAddress $PreferredDNS

# Configure vSwitch0
Write-Host -Object 'Configuring Management vSwitch'
$vs0 = Get-VirtualSwitch -Name vSwitch0
Add-VirtualSwitchPhysicalNetworkAdapter -VirtualSwitch $vs0 -VMHostPhysicalNic (Get-VMHostNetworkAdapter -Physical -Name $VmnicInterface[2]) -Confirm:$False

# Configure new standard vSwitch for iSCSI/vMotion
Write-Host -Object 'Configuring new vSwitch for vMotion/iSCSI'
$vs2 = New-VirtualSwitch -Name 'vSwitch2' -Mtu $MTU -Nic $VmnicInterface[1], $VmnicInterface[3] -Confirm:$False

# Configure new standard vSwitch for iSCSI/vMotion
Write-Host -Object 'Configuring new vSwitch for vMotion/iSCSI'
$vs3 = New-VirtualSwitch -Name 'vSwitch3' -Mtu $MTU -Nic $VmnicInterface[1], $VmnicInterface[3] -Confirm:$False

# Removes "VM Network" from the vSwitch0 and Creates a new VM Network
  get-VirtualPortGroup  | where { $_.Name -like "VM Network"} |  Remove-VirtualPortGroup  -Confirm:$false
  $vs1 = New-VirtualSwitch -Name 'vSwitch1' -Nic $VmnicInterface[1], $VmnicInterface[3] -Confirm:$False
  New-VirtualPortGroup -VirtualSwitch $vs1 -name $DataName -VLanId $DataVlan
  Get-VirtualPortGroup -name $DataName | Get-NicTeamingPolicy | Set-NicTeamingPolicy -MakeNicActive $vmnic[0],$vmnic[3],$vmnic[5],$vmnic[6]


# Configure vMotion
Write-Host -Object 'Configuring vMotion Port Group'
New-VirtualPortGroup -Name 'vMotion' -VirtualSwitch $vs2 -VLanId $vMotionVlan
New-VMHostNetworkAdapter -PortGroup vMotion -VirtualSwitch $vs1 -IP $vMotionIP -SubnetMask $subnetMask -VMotionEnabled: $True -Mtu $MTU

# Configure NTP
$ESXhosts = Get-VMHost
foreach ($ESX in $ESXhosts)
{
  Write-Host -Object "Target = $ESX"
  Add-VMHostNtpServer -VMHost $ESX -NtpServer $NTPServers -Confirm:$False
  Set-VMHostService -HostService (Get-VMHostService -VMHost (Get-VMHost $ESX) | Where-Object -FilterScript {
      $_.key -eq 'ntpd'
  }) -Policy 'Automatic'
  Get-VMHostFirewallException -VMHost $ESX -Name 'NTP Client' | Set-VMHostFirewallException -Enabled:$True
  $ntpd = Get-VMHostService -VMHost $ESX | Where-Object -FilterScript {
    $_.Key -eq 'ntpd'
  }
  Restart-VMHostService -HostService $ntpd -Confirm:$False
  # Go ahead and update the time to match host time
  $t = Get-Date
  $dst = Get-VMHost | ForEach-Object -Process {
    Get-View -VIObject $_.ExtensionData.ConfigManager.DateTimeSystem
  }
  $dst.UpdateDateTime((Get-Date -Date ($t.ToUniversalTime()) -Format u))
}

# Enable/Disable SSH
if ($EnableSsh -eq 'True') 
{
  Write-Host -Object 'The SSH Service will be set to start when the hosts boots'
  Get-VMHostService |
  Where-Object -FilterScript {
    $_.Key -eq 'TSM-SSH'
  } |
  Set-VMHostService -Policy On
  Get-VMHostService |
  Where-Object -FilterScript {
    $_.Key -eq 'TSM-SSH'
  } |
  Start-VMHostService
  Get-AdvancedSetting -Entity (Get-VMHost) -Name 'UserVars.SuppressShellWarning' | Set-AdvancedSetting -Value 1 -Confirm:$False
}
Else 
{
  Write-Host -Object 'The SSH Service will remain disabled'
}
      
# Configure Licensing
$licMgr = Get-View -Id 'LicenseManager-ha-license-manager'
$licMgr.UpdateLicense($License, $null)

# Remove Host from Maintenance
   Set-VMHost -VMHost $Hostname -State Connected 

#Restart the host to apply the timeout settings
if ($RebootHost -eq $True)
{
  Restart-VMHost -VMHost $Hostname -Confirm:$False
}

Disconnect-VIServer -Server * -Confirm:$False
