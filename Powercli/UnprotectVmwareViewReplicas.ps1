##############################################################################
#
#  Purpose: Build Commands to remove Unprotection VMware View Replicas
#  Created By: Chris Towles
#  Site: http://www.christowles.com
#  When: 11/23/2010
#  Version: 1.1
#  Change List
#
##############################################################################
$vCenter = Read-Host "Please enter your Vmware VSphere IP or DNS Name"
$ViewComposer = Read-Host "Please enter ViewComposer IP or DNS Name"
$VMwareUserName = Read-Host "Please enter your Vmware VSphere UserName - shown in the in the command but is not used."
$VMwarePassword = Read-Host "Please enter your Vmware VSphere Password - shown in the in the command but is not used."

function Get-VMFolder ($VirtualMachine) {

	$FoundVMs = Get-VM $VirtualMachine -ErrorAction SilentlyContinue

	if ( $FoundVMs -ne $null) {

		foreach($vm in $FoundVMs){

			$NetFolder = Get-View $vm.Folder

			$folderPath = @()
			$folderPath += $NetFolder.Name
			$folder = $null
			$folder = Get-Folder -Id $NetFolder.Parent | select -Index 0 -ErrorAction SilentlyContinue
			$folderPath += Get-ParentFolder $folder

			[string] $path = ""
			foreach ($part in $folderPath) {
				$path = "/$part" + $path
			}

			$path + "/$vm"

		}
	}
}

Function  Get-ParentFolder ($NetFolder) {
	$NetFolder.Name
	if($NetFolder.ParentID  -ne $null)
	{
		if($NetFolder.ParentID -match 'DataCenter-*'){
			$NetFolder.Parent.Name
		}
		else{
			$folder = Get-Folder -Id $NetFolder.ParentID
			Get-ParentFolder $folder
		}
	}
}

Connect-VIServer $vCenter
$VMPaths = Get-VMFolder "replica*"

$CommandString = @()
$CommandString += "CD C:\Program Files (X86)\VMware\VMware View Composer\"
$CommandString += ""

Write-host "Found the following Replicas"
foreach($vmpath in $VMPaths) {
	$vmpath
	$CommandString += "sviconfig -operation=unprotectentity -VcUrl=https://$ViewComposer/sdk -Username=$VMwareUserName -Password=$VMwarePassword -InventoryPath=$vmpath -Recursive=false"
	$CommandString += ""
}

$Tempfile = "$Env:TEMP\" + "unprotectentity.txt"
Remove-Item $Tempfile -Force -ErrorAction SilentlyContinue #delete file incase it already exists

####### Open the File to display the commands #######
Set-Content $Tempfile $CommandString
Start notepad  $Tempfile -Wait
Remove-Item $Tempfile -Force -ErrorAction SilentlyContinue