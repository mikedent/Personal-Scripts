# Connect to vCenter 
Connect-VIServer -Server 'scr911dvc.sccecc.netcom.int' -User 'administrator@vsphere.local' -Password 'snf1p)g=TA{-E+j'
$datacenter = 'SCCECC RMS'

# Create Main Folders
#(Get-View (Get-View -viewtype datacenter -filter @{"name"=$DataCenter}).vmfolder).CreateFolder("CAD Servers")
(Get-View (Get-View -viewtype datacenter -filter @{"name"=$DataCenter}).vmfolder).CreateFolder("Inform RMS")
(Get-View (Get-View -viewtype datacenter -filter @{"name"=$DataCenter}).vmfolder).CreateFolder("Management")
#(Get-View (Get-View -viewtype datacenter -filter @{"name"=$DataCenter}).vmfolder).CreateFolder("VDI")
(Get-View (Get-View -viewtype datacenter -filter @{"name"=$DataCenter}).vmfolder).CreateFolder("Templates")
#(Get-View (Get-View -viewtype datacenter -filter @{"name"=$DataCenter}).vmfolder).CreateFolder("Citrix")

# Create Sublevel folders
(Get-View -viewtype folder -filter @{"name"="Management"}).CreateFolder("Nutanix")
(Get-View -viewtype folder -filter @{"name" = "Management" }).CreateFolder("vSphere")
(Get-View -viewtype folder -filter @{"name" = "Management" }).CreateFolder("Zerto")
#(Get-View -viewtype folder -filter @{"name"="Nutanix"}).CreateFolder("CVM")

Disconnect-VIServer *