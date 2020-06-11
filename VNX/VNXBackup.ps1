############################
#
# Reference: VNX CLI Docs
# Script: VNX BACKUPS
#
# Date: 2015-01-23 14:30:00
#
# Version Update:
# 1.0 David Ring
#
############################

######## Banner ########
Write-Host " "
Write-Host "#######################################"
Write-Host "## VNX Configuration & LOGS Backup  ##"
Write-Host "#######################################"


### VNX SP IP's, User/PW & Backup Location ###
$SPAIP = Read-Host 'IP Address for Storage Processor A:'
$SPBIP = Read-Host 'IP Address for Storage Processor B:'
$User = Read-Host 'VNX Username:'
$Password = Read-Host 'VNX Password:'
$BackupLocation = Read-Host "Backup Location:(A sub-dir with the current Time & Date will be created):"

$ArrayConfig = (naviseccli -user $User -password $Password -scope 0 -h $SPAIP getagent | Select-String "Serial No:")
$ArrayConfig = $ArrayConfig -replace “Serial No:”,“”
$ArrayConfig = $ArrayConfig -replace “           ”,“”

$BackupLocation = (join-path -Path $BackupLocation -ChildPath ($ArrayConfig +"_"+ "$(date -f HHmmddMMyyyy)"))
IF(!(Test-Path "$BackupLocation")){new-item "$BackupLocation" -ItemType directory | Out-Null}
$BackupLocation =  "`"$BackupLocation`""


Write-Host "Storage Processor 'A':" $SPAIP
Write-Host "Storage Processor 'B':" $SPBIP
Write-Host "VNX Username:" $User
Write-Host "VNX Password:" $Password
Write-Host "VNX Serial Number:" $ArrayConfig
Write-Host "Backup Location Entered:" $BackupLocation

Start-Sleep -s 10


$BackupName = $ArrayConfig+"_"+$(date -f HHmmddMMyyyy)+".xml" ; naviseccli -user $User -password $Password -scope 0 -h $SPAIP arrayconfig -capture -output $BackupLocation"\"$BackupName

Write-Host $ArrayConfig "Configuration Data Has Been Backed Up In XML Format!"

Start-Sleep -s 5

### Gather & Retrieve SP Collects for both Storage Processors ###
Write-Host "Now Generating Fresh Storage Processor 'A' & 'B' Collects!"
$GenerateSPA = naviseccli -user $User -password $Password -scope 0 -h $SPAIP spcollect -messner
$GenerateSPB = naviseccli -user $User -password $Password -scope 0 -h $SPBIP spcollect -messner
Start-Sleep -s 10


### Storage Processor 'A' LOG Collection ###

## WHILE SP_A '*RUNLOG.TXT' FILE EXISTS THEN HOLD ...RESCAN EVERY 90 SECONDS ##
Do {
$listSPA = naviseccli -user $User -password $Password -scope 0 -h $SPAIP managefiles -list | select-string "_runlog.txt"
$listSPA
Start-Sleep -s 90
Write-Host "Generating Log Files For Storage Processor 'A' Please Wait!"
}
While ($listSPA -like '*runlog.txt')

Write-Host "Generation of SP-'A' Log Files Now Complete! Proceeding with Backup."

Start-Sleep -s 15

$latestSPA = naviseccli -user $User -password $Password -scope 0 -h $SPAIP managefiles -list | Select-string "data.zip" | Select-Object -Last 1
$latestSPA = $latestSPA -split "  "; $latestSPA=$latestSPA[6]
$latestSPA
$BackupSPA = naviseccli -user $User -password $Password -scope 0 -h $SPAIP managefiles -retrieve -path $BackupLocation -file $latestSPA -o

Start-Sleep -s 10


### Storage Processor 'B' LOG Collection ###

## WHILE SP_B '*RUNLOG.TXT' FILE EXISTS THEN HOLD ...RESCAN EVERY 15 SECONDS ##
Do {
$listSPB = naviseccli -user $User -password $Password -scope 0 -h $SPBIP managefiles -list | select-string "_runlog.txt"
$listSPB
Start-Sleep -s 15
Write-Host "Generating Log Files For Storage Processor 'B' Please Wait!"
}
While ($listSPB -like '*runlog.txt')

Write-Host "Generation of SP-'B' Log Files Now Complete! Proceeding with Backup."

Start-Sleep -s 10

$latestSPB = naviseccli -user $User -password $Password -scope 0 -h $SPBIP managefiles -list | Select-string "data.zip" | Select-Object -Last 1
$latestSPB = $latestSPB -split "  "; $latestSPB=$latestSPB[6]
$latestSPB
$BackupSPB = naviseccli -user $User -password $Password -scope 0 -h $SPBIP managefiles -retrieve -path $BackupLocation -file $latestSPB -o

$BackupLocation = $BackupLocation -replace '"', ""
invoke-item $BackupLocation

Read-Host "Confirm Presence of 'Array Capture XML' and 'SP Collects' in the Backup Directory!"
