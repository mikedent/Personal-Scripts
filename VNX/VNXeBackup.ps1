#################################
#
# Reference: VNXe UEMCLI Docs
# Script:VNXe BACKUPS
# Date: 2015-02-10 17:30:00										 			 
#
# Version Update:                                         
# 1.0 David Ring            	
#					 
#################################

######## Banner ########
Write-Host " "
Write-Host "#########################################################"
Write-Host "#######       VNXe Config and LOGS Backup        ########"
Write-Host "#########################################################"
Write-Host " "


##### Backup Location #####
$BackupLocation = Read-Host "Backup Location:(A sub-dir with the current Time & Date will be created):"
$BackupLocation = (join-path -Path $BackupLocation -ChildPath "$(date -f HHmmddMMyyyy)")	
IF(!(Test-Path "$BackupLocation")){new-item "$BackupLocation" -ItemType directory | Out-Null}
$BackupLocation =  "`"$BackupLocation`""

Write-Host "Backup Location Entered:" $BackupLocation

Start-Sleep -s 3

########################
### VNXe GEN1 Backup ###
########################
$VNXe = Read-Host 'VNXe 3150/3300 Present? y/n:'
if ($VNXe -eq "y") {
$VNXeIP = Read-Host 'VNXe IP Address:'
$VNXePW = Read-Host 'VNXe Service Password:'
Write-Host " "
Write-Host "########################################"
Write-Host "#######  VNXe 3150/3300 Backup  ########"
Write-Host "########################################"
Write-Host " "
Write-Host "VNXe IP Address:" $VNXeIP
Write-Host "VNXe Service Password:" $VNXePW
Write-Host " "
Start-Sleep -s 3
$VNXeConfig = (uemcli.exe -d $VNXeIP -u service -p $VNXePW -download -d $BackupLocation config)
Write-Host "### VNXe Config Backup Complete. ###"
Write-Host " "
Write-Host "### Now Generating VNXe Log Files! ###"
$VNXeConfig = (uemcli.exe -d $VNXeIP -u service -p $VNXePW /service/system collect -serviceInfo)
$VNXeConfig = (uemcli.exe -d $VNXeIP -u service -p $VNXePW -download -d $BackupLocation serviceInfo)
Write-Host " "
Write-Host "##################################################"
Write-Host "#######    VNXe GEN1 Backup Complete      ########"
Write-Host "##################################################"
Write-Host " "
}


########################
### VNXe GEN2 Backup ###
########################
$VNXe = Read-Host 'VNXe 3200 Present? y/n:'
if ($VNXe -eq "y") {
$VNXeIP = Read-Host 'VNXe IP Address:'
$VNXePW = Read-Host 'VNXe Service Password:'
Write-Host " "
Write-Host "####################################"
Write-Host "########  VNXe 3200 Backup  ########"
Write-Host "####################################"
Write-Host " "
Write-Host "VNXe IP Address:" $VNXeIP
Write-Host "VNXe Service Password:" $VNXePW
Write-Host " "
Start-Sleep -s 3
$VNXeConfig = (uemcli.exe -d $VNXeIP -u service -p $VNXePW /service/system collect -config -showPrivateData)
$VNXeConfig = (uemcli.exe -d $VNXeIP -u service -p $VNXePW -download -d $BackupLocation config)
Write-Host "### VNXe Config Backup Complete. ###"
Write-Host " "
Write-Host "### Now Generating VNXe Log Files! ###"
$VNXeLOGS = (uemcli.exe -d $VNXeIP -u service -p $VNXePW /service/system collect -serviceInfo)
$VNXeLOGS = (uemcli.exe -d $VNXeIP -u service -p $VNXePW -download -d $BackupLocation serviceInfo)
Write-Host " "
Write-Host "##################################################"
Write-Host "#######     VNXe GEN2 Backup Complete     ########"
Write-Host "##################################################"
Write-Host " "
}


Start-Sleep -s 3

$BackupLocation = $BackupLocation -replace '"', ""
invoke-item $BackupLocation

Read-Host "Confirm Presence of 'Config File' and 'LOG Files's' in the Backup Directory!"