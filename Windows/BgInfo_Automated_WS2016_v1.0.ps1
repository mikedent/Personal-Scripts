
##-------------------------------------------------------------------
## Name           Utils Automated
## Usage          Utils_Automated_v1.0.ps1
## Note           Change variables were needed to fit your needs
## PSVersion      Windows PowerShell 5.0
## Creator        Wim Matthyssen
## Date           21/02/17
## Version        1
##-------------------------------------------------------------------


## Requires -RunAsAdministrator


## Variables

$UtilsUrl = 'https://download.sysinternals.com/files/Utils.zip'
$LogonBgiUrl = 'http://scug.be/wim/files/2017/02/LogonBgi.zip'
$UtilsZip = 'C:\Utils\Utils.zip'
$UtilsFolder = 'C:\Utils'
$UtilsEula = 'C:\Utils\Eula.txt'
$LogonBgiZip = 'C:\Utils\LogonBgi.zip'
$ForegroundColor1 = 'Red'
$ForegroundColor2 = 'Yellow'
$UtilsRegPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run'
$UtilsRegKey = 'Utils'
$UtilsRegKeyValue = 'C:\Utils\Utils.exe C:\Utils\logon.bgi /timer:0 /nolicprompt'

## Set date/time variable and write blank lines

$global:currenttime= Set-PSBreakpoint -Variable currenttime -Mode Read -Action { $global:currenttime= Get-Date }
for ($i = 1; $i -lt 4; $i++) {write-host}
Write-Host "Download started" $currenttime -foregroundcolor $ForegroundColor1

#Create Utils folder on C: if not exists

If(!(test-path $UtilsFolder))
{
New-Item -ItemType Directory -Force -Path $UtilsFolder
Write-Host 'Utils folder created' -foregroundcolor $ForegroundColor2
}


## Download, save and extract latest Utils software to C:\Utils

function AllJobs-UtilsZip{
Import-Module BitsTransfer
Start-BitsTransfer -Source $UtilsUrl -Destination $UtilsZip
Expand-Archive -LiteralPath $UtilsZip -DestinationPath $UtilsFolder
Remove-Item $UtilsZip
Remove-Item $UtilsEula
for ($i = 1; $i -lt 2; $i++) {write-host}
Write-Host 'Utils.exe available' $currenttime -foregroundcolor $ForegroundColor2
}
AllJobs-UtilsZip


## Download, save and extract logon.bgi file to C:\Utils

function AllJobs-LogonBgiZip{
Invoke-WebRequest -Uri $LogonBgiUrl -OutFile $LogonBgiZip
Expand-Archive -LiteralPath $LogonBgiZip -DestinationPath $UtilsFolder
Remove-Item $LogonBgiZip
for ($i = 1; $i -lt 2; $i++) {write-host}
Write-Host 'logon.bgi available' $currenttime -foregroundcolor $ForegroundColor2
}
AllJobs-LogonBgiZip


## Create Utils Registry Key to AutoStart

function Add-UtilsRegKey{
New-ItemProperty -Path $UtilsRegPath -Name $UtilsRegKey -PropertyType "String" -Value $UtilsRegKeyValue
Write-Host 'Utils regkey added' -ForegroundColor $ForegroundColor2 
}
Add-UtilsRegKey


## Run Utils

C:\Utils\Utils.exe C:\Utils\logon.bgi /timer:0 /nolicprompt
for ($i = 1; $i -lt 2; $i++) {write-host}
Write-Host 'Utils has run' -foregroundcolor $ForegroundColor1


## Close PowerShell windows upon completion

stop-process -Id $PID 

##-------------------------------------------------------------------