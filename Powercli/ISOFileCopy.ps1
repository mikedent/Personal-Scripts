
# Copies all ISO files from directory to specific datastore
# Modify these settings for your requirements
#
# The script does the following:
# 1. Captures variables specific to the host environment (Datastore, ISO Folder)
# 2. Authentiates to vCenter and copies all ISO files to Datastore

<#	
	.NOTES
	===========================================================================
	 Created on:   	6/11/2015
	 Created by:   	Mike Dent
	 Filename:     	ISOFileCopy.ps1
	===========================================================================
	.DESCRIPTION
    	 Copies all ISO files from directory to specific datastore

#>

$vCenter = Read-Host "Enter vCenter Address"
$vCenterCreds = Get-Credential
$ISODrive = "E:\WindowsISO"


# Connect to vCenter
connect-viserver $vCenter -Credential $vCenterCreds

# Create new PSDrive based on ISO datastore location
New-PSDrive -location (get-datastore $Datastore) -name ISO -PSProvider VimDatastore -Root '\'

# Create variable of ISO Drive
$isos = ls $ISODrive | % {$_.Name}

# Loop thru folder to copy each ISO file
foreach($iso in $isos){    
    Write-Host "copy $($iso) to ISO Datastore" -fore Yellow
    Copy-DatastoreItem -item $ISODrive\$iso -Destination ISO:\

    
    Write-Host "Done Copying Files" -fore Green
}

# Disconnect from vCenter
Write-Host "Disconnecting from vCenter -fore Green"
Disconnect-VIServer *