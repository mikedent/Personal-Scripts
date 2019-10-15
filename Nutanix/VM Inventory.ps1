<#
.SYNOPSIS
Creates a complete inventory of a Nutanix environment.
.DESCRIPTION
Creates a complete inventory of a Nutanix Cluster configuration using CSV and PowerShell.
.PARAMETER nxIP
IP address of the Nutanix node you're making a connection too.
.PARAMETER nxUser
Username for the connection to the Nutanix node
.PARAMETER nxPassword
Password for the connection to the Nutanix node
.EXAMPLE
PS C:\PSScript > .\nutanix_inventory.ps1 -nxIP "99.99.99.99.99" -nxUser "admin"
.INPUTS
None.  You cannot pipe objects to this script.
.OUTPUTS
No objects are output from this script.  
This script creates a CSV file.
.NOTES
NAME: Nutanix_Inventory_Script_v3.ps1
VERSION: 1.0
AUTHOR: Kees Baggerman with help from Andrew Morgan, Michell Grauwman and Dave Brett
LASTEDIT: March 2019
#>
# Setting parameters for the connection
[CmdletBinding(SupportsShouldProcess = $False, ConfirmImpact = "None") ]
Param(
# Nutanix cluster IP address
[Parameter(Mandatory = $true)]
[Alias('IP')] [string] $nxIP,    
# Nutanix cluster username
[Parameter(Mandatory = $true)]
[Alias('User')] [string] $nxUser,
# Nutanix cluster password
[Parameter(Mandatory = $true)]
[Alias('Password')] [String] $nxPassword
)
# Converting the password to a secure string which isn't accepted for our API connectivity
$nxPasswordSec = ConvertTo-SecureString $nxPassword -AsPlainText -Force
Function write-log {
<#
.Synopsis
Write logs for debugging purposes
.Description
This function writes logs based on the message including a time stamp for debugging purposes.
#>
param (
$message,
$sev = "INFO"
)
if ($sev -eq "INFO") {
write-host "$(get-date -format "hh:mm:ss") | INFO | $message"
}
elseif ($sev -eq "WARN") {
write-host "$(get-date -format "hh:mm:ss") | WARN | $message"
}
elseif ($sev -eq "ERROR") {
write-host "$(get-date -format "hh:mm:ss") | ERROR | $message"
}
elseif ($sev -eq "CHAPTER") {
write-host "`n`n### $message`n`n"
}
} 
# Adding PS cmdlets
$loadedsnapins = (Get-PSSnapin -Registered | Select-Object name).name
if (!($loadedsnapins.Contains("NutanixCmdletsPSSnapin"))) {
Add-PSSnapin -Name NutanixCmdletsPSSnapin 
}
if ($null -eq (Get-PSSnapin -Name NutanixCmdletsPSSnapin -ErrorAction SilentlyContinue)) {
write-log -message "Nutanix CMDlets are not loaded, aborting the script"
break
}
$debug = 2
Function Get-Hosts {
<#
.Synopsis
This function will collect the hosts within the specified cluster.
.Description
This function will collect the hosts within the specified cluster using REST API call based on Invoke-RestMethod
#>
Param (
[string] $debug
)
$credPair = "$($nxUser):$($nxPassword)"
$encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
$headers = @{ Authorization = "Basic $encodedCredentials" }
$URL = "https://$($nxIP):9440/api/nutanix/v3/hosts/list"
$Payload = @{
kind   = "host"
offset = 0
length = 999
} 
$JSON = $Payload | convertto-json
try {
$task = Invoke-RestMethod -Uri $URL -method "post" -body $JSON -ContentType 'application/json' -headers $headers;
}
catch {
Start-Sleep 10
write-log -message "Going once"
$task = Invoke-RestMethod -Uri $URL -method "post" -body $JSON -ContentType 'application/json' -headers $headers;
}
write-log -message "We found $($task.entities.count) hosts in this cluster."
Return $task
} 
Function Get-VMs {
<#
.Synopsis
This function will collect the VMs within the specified cluster.
.Description
This function will collect the VMs within the specified cluster using REST API call based on Invoke-RestMethod
#>
Param (
[string] $debug
)
$credPair = "$($nxUser):$($nxPassword)"
$encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
$headers = @{ Authorization = "Basic $encodedCredentials" }
write-log -message "Executing VM List Query"
$URL = "https://$($nxIP):9440/api/nutanix/v3/vms/list"
$Payload = @{
kind   = "vm"
offset = 0
length = 999
} 
$JSON = $Payload | convertto-json
try {
$task = Invoke-RestMethod -Uri $URL -method "post" -body $JSON -ContentType 'application/json' -headers $headers;
}
catch {
Start-Sleep 10
write-log -message "Going once"
$task = Invoke-RestMethod -Uri $URL -method "post" -body $JSON -ContentType 'application/json' -headers $headers;
}
write-log -message "We found $($task.entities.count) VMs."
Return $task
} 
Function Get-DetailVM {
<#
.Synopsis
This function will collect the speficics of the VM we've specified using the Get-VMs function as input.
.Description
This function will collect the speficics of the VM we've specified using the Get-VMs function as input using REST API call based on Invoke-RestMethod
#>
Param (
[string] $uuid,
[string] $debug
)
$credPair = "$($nxUser):$($nxPassword)"
$encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
$headers = @{ Authorization = "Basic $encodedCredentials" }
$URL = "https://$($nxIP):9440/api/nutanix/v3/vms/$($uuid)"
try {
$task = Invoke-RestMethod -Uri $URL -method "get" -headers $headers;
}
catch {
Start-Sleep 10
write-log -message "Going once"
}  
Return $task
} 
Function Get-DetailHosts {
Param (
[string] $uuid,
[string] $debug
)
$credPair = "$($nxUser):$($nxPassword)"
$encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
$headers = @{ Authorization = "Basic $encodedCredentials" }
$URL = "https://$($nxIP):9440/api/nutanix/v3/hosts/$($uuid)"
try {
$task = Invoke-RestMethod -Uri $URL -method "get" -headers $headers;
}
catch {
Start-Sleep 10
$task = Invoke-RestMethod -Uri $URL -method "get" -headers $headers;
write-log -message "Going once"
}  
Return $task
} 
# Selecting all the GPUs and their devices IDs in the cluster
$GPU_List = $null
$hosts = Get-Hosts -ClusterPC_IP $nxIP -nxPassword $nxPassword -clusername $nxUser -debug $debug
Foreach ($Hypervisor in $hosts.entities) {
$detail = Get-DetailHosts -ClusterPC_IP $nxIP -nxPassword $nxPassword -clusername $nxUser -debug $debug -uuid $Hypervisor.metadata.uuid
[array]$GPU_List += $detail.status.resources.gpu_list
}
write-log -message "Collecting vGPU profiles and Device IDs"
# Connecting to the Nutanix Cluster
$nxServerObj = Connect-NTNXCluster -Server $nxIP -UserName $nxUser -Password $nxPasswordSec -AcceptInvalidSSLCerts
write-log -Message "Connecting to cluster $nxIp"
if ($null -eq (get-ntnxclusterinfo)) {
write-log -message "Cluster connection isn't available, abborting the script"
break
}
else {
write-log -message "Connected to Nutanix cluster $nxIP"
}
# Fetching data and putting into CSV
$vms = @(get-ntnxvm | Where-Object {$_.controllerVm -Match "false"}) 
write-log -message "Grabbing VM information"
write-log -message "Currently grabbing information on $($vms.count) VMs"
$FullReport = @()
foreach ($vm in $vms) {                        
$usedspace = 0
if (!($vm.nutanixvirtualdiskuuids.count -le $null)) {
write-log -message "Grabbing information on $($vm.vmName)"
foreach ($UUID in $VM.nutanixVirtualDiskUuids) {
$usedspace += (Get-NTNXVirtualDiskStat -Id $UUID -Metrics controller_user_bytes).values[0]
}
}
if ($vm.gpusInUse -eq "true") {
$myvmdetail = Get-DetailVM -ClusterPC_IP $nxIP -nxPassword $nxPassword -clusername $nxUser -debug $debug -uuid $vm.uuid
$newVMObject = $MyVMdetail
$devid = $newVMObject.spec.resources.gpu_list
$GPUUsed = $GPU_List | Where-Object {$_.device_id -eq $devid.device_id} 
$VMGPU = $GPUUsed | select-object {$_.name} -unique
$VMGPU1 = $VMGPU.'$_.name'
}
else {
$VMGPU1 = $Null
}
if ($usedspace -gt 0) {
$usedspace = [math]::round($usedspace / 1gb, 0)
}
$container = "NA"
if (!($vm.vdiskFilePaths.count -le 0)) {
$container = $vm.vdiskFilePaths[0].split('/')[1]
}
if ($vm.nutanixGuestTools.enabled -eq 'False') { $NGTstate = 'Installed'}
else { 
$NGTstate = 'Not Installed'
}
$props = [ordered]@{
"VM Name"                       = $vm.vmName
"Container"                     = $container
"Protection Domain"             = $vm.protectionDomainName
"Host Placement"                = $vm.hostName
"Power State"                   = $vm.powerstate
"Network Name"                  = $myvmdetail.status.resources.nic_list.subnet_reference.name
"Network adapters"              = $vm.numNetworkAdapters
"IP Address(es)"                = $vm.ipAddresses -join ","
"vCPUs"                         = $vm.numVCpus
"Number of Cores"               = $myvmdetail.spec.resources.num_sockets
"Number of vCPUs per core"      = $myvmdetail.spec.resources.num_vcpus_per_socket
"vRAM (GB)"                     = [math]::round($vm.memoryCapacityInBytes / 1GB, 0)
"Disk Count"                    = $vm.nutanixVirtualDiskUuids.count
"Provisioned Space (GB)"        = [math]::round($vm.diskCapacityInBytes / 1GB, 0)
"Used Space (GB)"               = $usedspace
"GPU Profile"                   = $VMGPU1
"VM description"                = $vm.description
"Guest Operating System"        = $vm.guestOperatingSystem
"VM Time Zone"                  = $myvmdetail.spec.resources.hardware_clock_timezone
"Nutanix Guest Tools installed" = $NGTState
} #End properties
$Reportobject = New-Object PSObject -Property $props
$fullreport += $Reportobject
}
$fullreport | Export-Csv -Path ~\Desktop\NutanixVMInventory.csv -NoTypeInformation -UseCulture -verbose:$false
write-log -message "Writing the information to the CSV"
# Disconnecting from the Nutanix Cluster
Disconnect-NTNXCluster -Servers *
write-log -message "Closing the connection to the Nutanix cluster $($nxIP)"
