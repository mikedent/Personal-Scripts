# vCenter Datastore Upgrade Script
# By Mike Dent
# Date 6/10/2015
#
# Creates the Data Center and Cluster within vCenter
# Modify these settings for your requirements
#
# The script does the following:
# 1. Creates the Data Center and Cluster with default HA/DRS settings
# 2. Adds ESXi hosts to the newly created cluster

$vcenter = Read-Host "Enter the vCenter address (IP or FQDN)"
<#$upgradestore = Read-Host "Enter the Datastore you wish to upgrade:"#>
$upgradestore = "OPD_VCENTER_LUN"
$movestore =  Read-Host "Enter the Datastore you wish to temporarily move to:"
$user = "root"
$pass = "Pdntsp@7"

<## Connect to vCenter 
Connect-VIServer $viserver -Credential $vccred#>

# Perform Datastore Upgrade
foreach ($datastore in $upgradestore) {
    Write-Host "You are on Datastore $datastore" -ForegroundColor green
    Upgrade-Datastore -upgradestore $datastore -server $vcenter -user $user -pass $pass -confirm:$false
}
 Write-Host "Done!" -ForegroundColor green


