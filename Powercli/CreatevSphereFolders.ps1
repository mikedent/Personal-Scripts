﻿# Connect to vCenter 
Connect-VIServer -Server jdvct01.jeffcom.local -User administrator@vsphere.local -Password 'Tr!t3cH1'
$datacenter = 'EBR PRimary'

# Create Main Folders
<#(Get-View (Get-View -viewtype datacenter -filter @{"name"=$DataCenter}).vmfolder).CreateFolder("CAD Servers")
(Get-View (Get-View -viewtype datacenter -filter @{"name"=$DataCenter}).vmfolder).CreateFolder("vSphere")
(Get-View (Get-View -viewtype datacenter -filter @{"name"=$DataCenter}).vmfolder).CreateFolder("Management")
(Get-View (Get-View -viewtype datacenter -filter @{"name"=$DataCenter}).vmfolder).CreateFolder("VDI")
(Get-View (Get-View -viewtype datacenter -filter @{"name"=$DataCenter}).vmfolder).CreateFolder("Template VMs")
#>
(Get-View (Get-View -viewtype datacenter -filter @{"name"=$DataCenter}).vmfolder).CreateFolder("Nutanix")

# Create Sublevel folders
#(Get-View -viewtype folder -filter @{"name"="VDI"}).CreateFolder("Desktops")
(Get-View -viewtype folder -filter @{"name"="Nutanix"}).CreateFolder("CVM")

Disconnect-VIServer *