#requires -Version 1.0
<## Author: Mike Dent
    # Product: VMware vSphere
    # Description: Script to create vSphere Datacenter and Cluster, and add hosts to Cluster
    #
    # The script does the following:
    # 1. Creates the Data Center and Cluster with default HA/DRS settings
    # 2. Adds ESXi hosts to the newly created cluster
    # Parameter Descriptions

    .PARAMETER VISERVER
    VMHost to configure Dump Collector settings for.

    .PARAMETER VCCRED

    .PARAMETER DATACENTER

    .PARAMETER CLUSTER

    .PARAMETER CLUSTERCONFIG

#>

#$viserver = Read-Host -Prompt 'Enter the vCenter address (IP or FQDN)'
#$vccred = Get-Credential
$datacenter = 'EBR CAD - DR'
$cluster = 'CAD'
$clusterconfig = Read-Host -Prompt 'Enter 0 for HA only, 1 for DRS only, or 2 for HA/DRS'


# Connect to vCenter 
Connect-VIServer -Server ebrdrvcenter.ebr911.net -User administrator@vsphere.local -Password "Tr!t3cH1"

# List of ESXi Hosts to Add to New Data Center
# Use the IP Addresses or FQDNs of the ESXi hosts to be added
# Example using IP: $esxhosts = "192.168.1.25","192.168.1.26"
# Example using FQDN: $esxhosts = "esx0.lab.local","esx1.lab.local"
$esxhosts = 'ebrdrvmhost01.ebr911.net','ebrdrvmhost02.ebr911.net','ebrdrvmhost03.ebr911.net'
#$esxhosts = '10.2.225.20','10.2.225.21','10.2.225.22'
# Prompt for ESXi Root Credentials
$esxcred = Get-Credential 

Write-Host -Object "Creating Datacenter $datacenter" -ForegroundColor green
$location = Get-Folder -NoRecursion
New-Datacenter -Location $location -Name $datacenter

# Create the cluster using defined variables
if ('0' -eq $clusterconfig)
{
  Write-Host -Object "Creating Cluster $cluster" -ForegroundColor green
  New-Cluster -Location $datacenter -Name $cluster -HAEnabled
}
ElseIf ('1' -eq $clusterconfig)
{
  Write-Host -Object "Creating Cluster $cluster" -ForegroundColor Green
  New-Cluster -Location $datacenter -Name $cluster -DrsEnabled
}
ElseIf ('2' -eq $clusterconfig)
{
  Write-Host -Object "Creating Cluster $cluster" -ForegroundColor Green
  New-Cluster -Location $datacenter -Name $cluster -DrsEnabled -HAEnabled
}
Else 
{
  Write-Host -Object "Creating Cluster $cluster" -ForegroundColor Green
  New-Cluster -Location $datacenter -Name $cluster 
}

foreach ($esx in $esxhosts) 
{
  Write-Host -Object "Adding ESX Host $esx to $datacenter/$cluster" -ForegroundColor green
  Add-VMHost -Name $esx -Location (Get-Cluster $cluster) -Credential $esxcred -Force -RunAsync -Confirm:$false
}

Write-Host -Object 'Done!' -ForegroundColor green

# Create Main Folders
(Get-View (Get-View -viewtype datacenter -filter @{"name"=$DataCenter}).vmfolder).CreateFolder("CAD Servers")
(Get-View (Get-View -viewtype datacenter -filter @{"name"=$DataCenter}).vmfolder).CreateFolder("vSphere Management")
(Get-View (Get-View -viewtype datacenter -filter @{"name"=$DataCenter}).vmfolder).CreateFolder("Management")
#(Get-View (Get-View -viewtype datacenter -filter @{"name"=$DataCenter}).vmfolder).CreateFolder("vm")
(Get-View (Get-View -viewtype datacenter -filter @{"name"=$DataCenter}).vmfolder).CreateFolder("Template VMs")

# Create Sublevel folders
(Get-View -viewtype folder -filter @{"name"="vSphere Management"}).CreateFolder("vCenter")
(Get-View -viewtype folder -filter @{"name"="vSphere Management"}).CreateFolder("vRealize")



Disconnect-VIServer -Server * -Confirm:$false