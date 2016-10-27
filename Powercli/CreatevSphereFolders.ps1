Connect-VIServer 172.19.52.2 -User administrator@vsphere.local -Password '8zMGBHPb#'
$DataCenter = 'ECS Data Center'

# Create Main Folders
(Get-View (Get-View -viewtype datacenter -filter @{"name"=$DataCenter}).vmfolder).CreateFolder("CAD Servers")
(Get-View (Get-View -viewtype datacenter -filter @{"name"=$DataCenter}).vmfolder).CreateFolder("vSphere")
(Get-View (Get-View -viewtype datacenter -filter @{"name"=$DataCenter}).vmfolder).CreateFolder("Management")
(Get-View (Get-View -viewtype datacenter -filter @{"name"=$DataCenter}).vmfolder).CreateFolder("VDI")
(Get-View (Get-View -viewtype datacenter -filter @{"name"=$DataCenter}).vmfolder).CreateFolder("Template VMs")

# Create Sublevel folders
(Get-View -viewtype folder -filter @{"name"="VDI"}).CreateFolder("Desktops")

Disconnect-VIServer * -Force