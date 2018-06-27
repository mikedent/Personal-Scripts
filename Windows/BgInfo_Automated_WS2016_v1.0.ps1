
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
$UtilsZip = 'C:\Utilities\Utils.zip'
$UtilsFolder = 'C:\Utilities'
$UtilsEula = 'C:\Utilities\Eula.txt'
$LogonBgiZip = 'C:\Utilities\LogonBgi.zip'
$ForegroundColor1 = 'Red'
$ForegroundColor2 = 'Yellow'
$UtilsRegPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run'
$UtilsRegKey = 'Utils'
$UtilsRegKeyValue = 'C:\Utilities\BgInfo.exe C:\Utilities\logon.bgi /timer:0 /nolicprompt'

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


## Create Utils Registry Key to AutoStart

function Add-UtilsRegKey{
New-ItemProperty -Path $UtilsRegPath -Name $UtilsRegKey -PropertyType "String" -Value $UtilsRegKeyValue
Write-Host 'Utils regkey added' -ForegroundColor $ForegroundColor2 
}
Add-UtilsRegKey


## Run Utils

C:\Utilities\BgInfo.exe C:\Utilities\logon.bgi /timer:0 /nolicprompt
for ($i = 1; $i -lt 2; $i++) {write-host}
Write-Host 'Utils has run' -foregroundcolor $ForegroundColor1

