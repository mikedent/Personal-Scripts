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

$viserver = Read-Host "Enter the vCenter address (IP or FQDN)"
$vccred = Get-Credential
$datacenter = "OPD DC"
$cluster = "CAD Cluster"
$clusterconfig = Read-Host "Enter 0 for HA only, 1 for DRS only, or 2 for HA/DRS"


# Connect to vCenter 
Connect-VIServer $viserver -Credential $vccred

# List of ESXi Hosts to Add to New Data Center
# Use the IP Addresses or FQDNs of the ESXi hosts to be added
# Example using IP: $esxhosts = "192.168.1.25","192.168.1.26"
# Example using FQDN: $esxhosts = "esx0.lab.local","esx1.lab.local"
$esxhosts = "192.168.120.218"

# Prompt for ESXi Root Credentials
$esxcred = Get-Credential 

Write-Host "Creating Datacenter $datacenter" -ForegroundColor green
$location = Get-Folder -NoRecursion
New-DataCenter -Location $location -Name $datacenter

# Create the cluster using defined variables
    if ("0" -eq $clusterconfig){
        Write-Host "Creating Cluster $cluster" -ForegroundColor green
        New-Cluster -Location $datacenter -Name $cluster -HAEnabled
    }
    ElseIf ("1" -eq $clusterconfig){
        Write-Host "Creating Cluster $cluster" -ForegroundColor Green
        New-Cluster -Location $datacenter -Name $cluster -DrsEnabled
    }
	Else {
        Write-Host "Creating Cluster $cluster" -ForegroundColor Green
        New-Cluster -Location $datacenter -Name $cluster 
    }

foreach ($esx in $esxhosts) {
  Write-Host "Adding ESX Host $esx to $datacenter/$cluster" -ForegroundColor green
  Add-VMHost -Name $esx -Location (Get-Cluster $cluster) -Credential $esxcred -Force -RunAsync -Confirm:$false
}

Write-Host "Done!" -ForegroundColor green


Disconnect-VIServer * -Confirm:$false