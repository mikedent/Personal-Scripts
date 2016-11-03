###########################################################################
# Start of the script - Description, Requirements & Legal Disclaimer
###########################################################################
# Author:
# Mike Dent
# Description:
# This script automates the deployment of the vRealize appliances for Log Insight and Operations Manager
################################################ 
# Requirements:
# - vCenter ServerName, Username and password to establish as session using PowerCLI to the vCenter
# - OVF File Locations for Log Insight and Operations Manager
# - Hostname, Datastore and Network Parameters for each 
# - Access permission to write in and create (or create it manually and ensure the user has permission to write within)the directory specified for logging
# - VMware PowerCLI, any version, installed on the host running the script
# - Run PowerShell as administrator with command "Set-ExecutionPolcity unrestricted"
################################################
# Configure the variables below
################################################

# Configure Log Directory for logging of activity
$LogDataDir = "$env:HOMEDRIVE\Scripts\LogOutput"

# Setting log directory for engine and current month
$CurrentMonth = Get-Date -Format MM.yy
$CurrentTime = Get-Date -Format hh.mm.ss
$CurrentLogDataDir = $LogDataDir + $CurrentMonth
$CurrentLogDataFile = $LogDataDir + $CurrentMonth + '\DeployvRealizeAppliances-' + $CurrentTime + '.txt'
# Testing path exists to engine logging, if not creating it
$ExportDataDirTestPath = Test-Path -Path $CurrentLogDataDir
if ($ExportDataDirTestPath -eq $False)
{
  New-Item -ItemType Directory -Force -Path $CurrentLogDataDir
}

# Load OVF/OVA locations into a variable for vRealize Log Insight and Operations Managers
$ovffileLI = 'Z:\Tritech Install Files\VMware\vRealize\VMware-vRealize-Log-Insight-3.6.0-4202923.ova'
$ovffileOM = 'Z:\Tritech Install Files\VMware\vRealize\vRealize-Operations-Manager-Appliance-6.3.0.4276418_OVF10.ovf'

### General VM Deplyment options ###
# Deployment Size Configuration: xsmall,small,medium,large,smallrc,largerc
$size = 'xsmall'

# Disk Format Configuration:  
$DiskFormat = 'Thin'

### Appliance Specific configurations ###
# Log Insight Configuration
$ApplianceName = 'SCSOVMLOG01'
$VMName = 'SCSOVMLOG01.e911.local'
$datastore = 'SCSO_MGMT_LUN_10'
$VMNetwork = 'VM MGMT'
$ipaddr0 = '10.93.0.183'
$netmask0 = '255.255.255.128'
$gateway = '10.93.0.129'
$dnsServer = '10.93.0.250'
$domainSearch = 'e911.local'
$domain = 'e911.local'

# Appliance password
$password = 'Tr!t3ch1'

# Operations Manager Configuration
$ApplianceNameOM = 'SCSOVMVROM01'
$datastoreOM = 'SCSO_MGMT_LUN_10'
$timeZoneOM = 'US/Eastern'
$VMNetworkOM = 'VM MGMT'
$ipaddr0OM = '10.93.0.182'
$netmask0OM = '255.255.255.128'
$gatewayOM = '10.93.0.129'
$dnsServerOM = '10.93.0.250'

################################################
# End Capturing of variables
################################################


################################################
# Functions for Importing Appliances
################################################

Function Import-LogInsight 
{
  <#
      .SYNOPSIS
      Describe purpose of "Import-LogInsight" in 1-2 sentences.

      .DESCRIPTION
      Add a more complete description of what the function does.

      .EXAMPLE
      Import-LogInsight
      Describe what this call does

      .NOTES
      Place additional notes here.

      .LINK
      URLs to related sites
      The first link is opened by Get-Help -Online Import-LogInsight

      .INPUTS
      List of input types that are accepted by this function.

      .OUTPUTS
      List of output types produced by this function.
  #>


  # Load OVF/OVA configuration into a variable
  $ovfConfiguration = Get-OvfConfiguration -Ovf $ovffileLI
  # OVF Configuration Parameters
  $ovfConfiguration.DeploymentOption.value = $size
  $ovfConfiguration.NetworkMapping.Network_1.value = $VMNetwork
  $ovfConfiguration.vami.VMware_vCenter_Log_Insight.ip0.Value = $ipaddr0
  $ovfConfiguration.vami.VMware_vCenter_Log_Insight.netmask0.Value = $netmask0
  $ovfConfiguration.vami.VMware_vCenter_Log_Insight.gateway.Value = $gateway
  $ovfConfiguration.vami.VMware_vCenter_Log_Insight.hostname.Value = $VMName
  $ovfConfiguration.vami.VMware_vCenter_Log_Insight.DNS.Value = $dnsServer
  $ovfConfiguration.vami.VMware_vCenter_Log_Insight.searchpath.Value = $domainSearch
  $ovfConfiguration.vami.VMware_vCenter_Log_Insight.searchpath.Value = $domain
  $ovfConfiguration.vm.rootpw.value = $password
  
  # Deploy the OVF/OVA with the config parameters
  Import-VApp -Source $ovffileLI -OvfConfiguration $ovfConfiguration -VMHost $VMHost -Datastore $datastore -DiskStorageFormat $DiskFormat -Name $ApplianceName
}
Function Import-OperationsManager 
{
  <#
      .SYNOPSIS
      Describe purpose of "Import-OperationsManager" in 1-2 sentences.

      .DESCRIPTION
      Add a more complete description of what the function does.

      .EXAMPLE
      Import-OperationsManager
      Describe what this call does

      .NOTES
      Place additional notes here.

      .LINK
      URLs to related sites
      The first link is opened by Get-Help -Online Import-OperationsManager

      .INPUTS
      List of input types that are accepted by this function.

      .OUTPUTS
      List of output types produced by this function.
  #>


  # Load OVF/OVA configuration into a variable
  $ovfConfiguration = Get-OvfConfiguration -Ovf $ovffileOM
  # OVF Configuration Parameters
  $ovfConfiguration.DeploymentOption.Value = $size
  $ovfConfiguration.NetworkMapping.Network_1.value = $VMNetworkOM
  $ovfConfiguration.vami.vRealize_Operations_Manager_Appliance.ip0.Value = $ipaddr0OM
  $ovfConfiguration.vami.vRealize_Operations_Manager_Appliance.netmask0.Value = $netmask0OM
  $ovfConfiguration.vami.vRealize_Operations_Manager_Appliance.gateway.Value = $gatewayOM
  $ovfConfiguration.vami.vRealize_Operations_Manager_Appliance.DNS.Value = $dnsServerOM
  $ovfconfig.common.vamitimezone.value = $timeZoneOM
  
  # Deploy the OVF/OVA with the config parameters
  Import-VApp -Source $ovffileOM -OvfConfiguration $ovfConfiguration -VMHost $VMHost -Datastore $datastoreOM -DiskStorageFormat $DiskFormat -Name $ApplianceNameOM
}


################################################
# Starting Install Process for selected Appliance
################################################
# Start Logging
Start-Transcript -Path $CurrentLogDataFile -NoClobber

# Connect to vCenter Instance
#$VIServer = Read-Host -Prompt 'Enter the vCenter Address to connect:' 
#$credentials = Get-Credential
#Connect-VIServer -Server $VIServer  -Credential $credentials
Connect-VIServer -Server 10.93.0.181 -User administrator@vsphere.local -Password 'Tr!t3cH1'

# Cluster Selection
Write-Host -Object 'Clusters Associated with this vCenter:'
$VMcluster  = '*'
ForEach ($VMcluster in (Get-Cluster $VMcluster)| Sort-Object)
{
  Write-Host -Object $VMcluster
}
Write-Host -Object 'Please enter the Cluster to Deploy To: '
$VMcluster  = Read-Host
$VMHost = Get-Cluster $VMcluster |
Get-VMHost |
Sort-Object -Property MemoryGB |
Select-Object -First 1

# Deployment Option
Write-Host -Object 'This script will import either vRealize Log Insight or vRealize Operations Manager with predefined values'
$importOption = Read-Host -Prompt 'Enter 1 to import Log Insight or 2 to import Operations Manager' 
If ($importOption -eq 1) 
{
  Import-LogInsight
}
ElseIf ($importOption -eq 2) 
{
  Import-OperationsManager
}
Else 
{
  Write-Host -Object 'PowerCLI is not installed - Please install.......quiting'
  exit
}
Disconnect-VIServer -Server * -Force -Confirm:$False
# End of per Host operations above
################################################
# Stopping logging
################################################
Stop-Transcript