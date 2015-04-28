
#===============================================================================================
# AUTHOR:  Tao Yang 
# DATE:    09/10/2008
# Version  1.1
# COMMENT: Windows 2008 Server (R2) Build Automated script - Main script for Internal network.
#===============================================================================================

##First of all, make sure there are enough real estate on the powershell console
$BufferWidth = 250
$BufferHeight = 600
$bUpdateSize = $false
$RawUI = (Get-Host).UI.RawUI
$BufferSize = $RawUI.BufferSize

if ($BufferSize.Width -lt $BufferWidth) {$BufferSize.Width = $BufferWidth; $bUpdateSize = $true}
if ($BufferSize.Height -lt $BufferHeight) {$BufferSize.Height = $BufferHeight; $bUpdateSize = $true}
if ($bUpdateSize -eq $true) {$RawUI.BufferSize = $BufferSize}

Remove-Variable bUpdateSize

##**Global Variables
#Set console properties
$Global:fgColor = "DarkYellow"
$Global:bgColor = "DarkMagenta"
$Global:Title = "Windows Server 2008, 2008 R2 and Windows 7 Build Script"
$Global:UserInputColor = "Yellow"
$Global:OnScreenMsgColor = "Green"
$Global:ErrorColor = "Red"

#Set Global variables
$Global:ErrorDetected = 0

#detect the operating system
$OS = Get-WmiObject Win32_OperatingSystem
$Global:OSMajorVersion = $OS.version.substring(0,3)
$Global:OSSKU = $OS.OperatingSystemSKU
$Global:OSCaption = $OS.Caption
$Global:OldCSName = $OS.CSName

#detect server hardware info
$CS = Get-WmiObject Win32_ComputerSystem
$Global:CSVendor = $CS.Manufacturer
$Global:CSModel = $CS.Model
$Global:CSRAM = ([math]::round($CS.TotalPhysicalMemory /1024/1024)).tostring() + " MB"
$Global:CSCPUCount = $CS.NumberOfProcessors
$Global:CSUserName = $CS.UserName

#System locale
$Global:oldCultureLCID = (Get-Culture).LCID
$Global:oldCultureName = (Get-Culture).Name

#Time Zone
$Global:CurrentTZName = (Get-WmiObject win32_timezone).Description

#Check capatibility: This script can only run on Windows Vista, Windows Server 2008, Windows Server 2008 R2 and Windows 7.
$ArrSupportedOSMajorVersion = @()
$ArrSupportedOSMajorVersion += "6.0"	#Windows Vista and Windows SErver 2008
$ArrSupportedOSMajorVersion += "6.1"	#Windows 7 and Windows SErver 2008 R2

if ($ArrSupportedOSMajorVersion -notcontains $Global:OSMajorVersion)
{
	Write-Host "Error: This Windows Build script is not designed to run on $Global:OsCaption!" -ForegroundColor $Global:ErrorColor
	Write-Host ""
	exit
}

#Get OS Architecture
$Global:OSArchitecture = $OS.OSArchitecture

##**Display Heading**
Clear-Host
Write-Host ""
Write-Host "#######################################################################" -foregroundcolor $Global:OnScreenMsgColor
Write-Host "# *Welcome to Windows 2008 (R2)/ Windows 7 Build Script               #" -foregroundcolor $Global:OnScreenMsgColor
Write-Host "# *Author: Tao Yang                                                   #" -foregroundcolor $Global:OnScreenMsgColor
Write-Host "# *Version: 2.5                                                       #" -foregroundcolor $Global:OnScreenMsgColor
Write-Host "# *Release Date: 11/09/2010                                           #" -foregroundcolor $Global:OnScreenMsgColor
Write-Host "# *Source: http://blog.tyang.org                                      #" -foregroundcolor $Global:OnScreenMsgColor
Write-Host "#######################################################################" -foregroundcolor $Global:OnScreenMsgColor
Write-Host ""
Write-Host ""
Write-Host "Basic System Information:" -ForegroundColor $Global:OnScreenMsgColor
Write-Host "*************************" -ForegroundColor $Global:OnScreenMsgColor
Write-Host ""
Write-Host "Computer Name:        " -ForegroundColor $Global:OnScreenMsgColor -NoNewline; Write-Host $Global:OldCSName -ForegroundColor $Global:UserInputColor
Write-Host "System Manufacturer:  " -ForegroundColor $Global:OnScreenMsgColor -NoNewline; Write-Host $Global:CSVendor -ForegroundColor $Global:UserInputColor
Write-Host "System Model:         " -ForegroundColor $Global:OnScreenMsgColor -NoNewline; Write-Host $Global:CSModel -ForegroundColor $Global:UserInputColor
Write-Host "Operating System:     " -ForegroundColor $Global:OnScreenMsgColor -NoNewline; Write-Host $Global:OSCaption -ForegroundColor $Global:UserInputColor
Write-Host "OS Architecture:      " -ForegroundColor $Global:OnScreenMsgColor -NoNewline; Write-Host $Global:OSArchitecture -ForegroundColor $Global:UserInputColor
Write-Host "Physical CPU Count:   " -ForegroundColor $Global:OnScreenMsgColor -NoNewline; Write-Host $Global:CSCPUCount -ForegroundColor $Global:UserInputColor
Write-Host "Physical Memory:      " -ForegroundColor $Global:OnScreenMsgColor -NoNewline; Write-Host $Global:CSRAM -ForegroundColor $Global:UserInputColor
Write-Host "System Locale:        " -ForegroundColor $Global:OnScreenMsgColor -NoNewline; Write-Host $Global:oldCultureName -ForegroundColor $Global:UserInputColor
Write-Host "Current Time Zone:    " -ForegroundColor $Global:OnScreenMsgColor -NoNewline; Write-Host $Global:CurrentTZName -ForegroundColor $Global:UserInputColor
Write-Host "Current User Name:    " -ForegroundColor $Global:OnScreenMsgColor -NoNewline; Write-Host $Global:CSUserName -ForegroundColor $Global:UserInputColor
Write-Host ""

##**Initiation**
# Clear $error
$error.clear()
$errorActionPreference = "SilentlyContinue"
$logentry = ""
$strComputer = "."
#Determine the file system path of this script
$thisScript = Split-Path $myInvocation.MyCommand.Path -Leaf
$scriptRoot = Split-Path(Resolve-Path $myInvocation.MyCommand.Path)
#File Path for GlobalSettings script (which is located on the same folder of this script)
$GlobalSettings = $scriptRoot + "\0_GlobalSettings.PS1"

#Load Global Settinsg
. $GlobalSettings

#Remove old log file
$logFile = Join-Path $ScriptRoot "BuildLog.log"
if (Test-Path $logFile)
{
	Remove-Item $logFile
	#Start logging
	if ($error.count -ne 0) { $Global:ErrorDetected = 1; for ($i = 1; $i -le $error.count; $i++) { $logentry = $error[$error.count - $i] ; logging $thisScript $logentry 1 } } else { logging $thisScript "old log file deleted." 2 }
	$error.clear()
	#End logging
}
$error.clear()

#Remove old Locale configuration file
if (Test-Path $Global:localeFile)
{
	Remove-Item $Global:localeFile
	#Start logging
	if ($error.count -ne 0) { $Global:ErrorDetected = 1; for ($i = 1; $i -le $error.count; $i++) { $logentry = $error[$error.count - $i] ; logging $thisScript $logentry 1 } } else { logging $thisScript "old locale configuration file deleted." 2 }
	$error.clear()
	#End logging
}
$error.clear()

#Start logging
if ($error.count -ne 0) { $Global:ErrorDetected = 1; for ($i = 1; $i -le $error.count; $i++) { $logentry = $error[$error.count - $i] ; logging $thisScript $logentry 1 } } else { logging $thisScript "$thisScript Initiation Completed." 0 }
$error.clear()
#End logging
##**Initiation section needs to be on top of this script. - this is different then other scripts. It contains a section of deleting the old log file.**


##Getting configuration settings from configuration.ini

#specify the config Ini file
$configIni = Join-Path $scriptRoot Configuration.ini -Resolve

#Registered Organisation can be overwritten from the config ini file
Get-Content $configIni | foreach-object { if (($_.split("="))[0] -eq "RegisteredOrg") { $Global:RegisteredOrg = ($_.split("="))[1] } }

#Registered Owner can be overwritten from the config ini file
Get-Content $configIni | foreach-object { if (($_.split("="))[0] -eq "RegisteredOwner") { $Global:RegisteredOwner = ($_.split("="))[1] } }

#Disabled Services
$Global:arrDisabledServices = @()
Get-Content $configIni | foreach-object { if (($_.split("="))[0] -eq "DisabledService") { $Global:arrDisabledServices += ($_.split("="))[1] } }

#Screen Saver Settings
Get-Content $configIni | foreach-object { if (($_.split("="))[0] -eq "ScreenSaverName") { $Global:ScreenSaverName = ($_.split("="))[1] } }
Get-Content $configIni | foreach-object { if (($_.split("="))[0] -eq "ScreenSaverTimeout") { $Global:ScreenSaverTimeout = ($_.split("="))[1] } }

#NTP Server
Get-Content $configIni | foreach-object { if (($_.split("="))[0] -eq "NTP") { $Global:NTP = ($_.split("="))[1] } }

#Locale Settings
Get-Content $configIni | foreach-object { if (($_.split("="))[0] -eq "UserLocale") { $Global:UserLocale = ($_.split("="))[1] } }
Get-Content $configIni | foreach-object { if (($_.split("="))[0] -eq "SystemLocale") { $Global:SystemLocale = ($_.split("="))[1] } }
Get-Content $configIni | foreach-object { if (($_.split("="))[0] -eq "ShortDate") { $Global:ShortDate = ($_.split("="))[1] } }
$Global:GEOID = Get-GEOID($Global:SystemLocale)

$LocaleXML = @"
<gs:GlobalizationServices xmlns:gs="urn:longhornGlobalizationUnattend">

   <!--User List-->
    <gs:UserList>
           <gs:User UserID="Current" CopySettingsToSystemAcct="true" CopySettingsToDefaultUserAcct="true"/>
    </gs:UserList>

	 <!--User Locale-->
    <gs:UserLocale>
        <gs:Locale Name="$Global:UserLocale" SetAsCurrent="true" ResetAllSettings="false">
		<gs:Win32>
			<gs:sShortDate>$Global:ShortDate</gs:sShortDate>
		</gs:Win32>
	</gs:Locale>
    </gs:UserLocale>

   <!--System locale-->
    <gs:SystemLocale Name="$Global:SystemLocale"/>
	 
 	<!--location-->
    <gs:LocationPreferences>
           <gs:GeoID Value="$Global:GEOID"/>
    </gs:LocationPreferences>
</gs:GlobalizationServices>

"@
$LocaleXML | Out-File $localeFile

#DNS Servers
$Global:arrDNSServers = @()
Get-Content $configIni | foreach-object { if (($_.split("="))[0] -eq "DNSServer") { $Global:arrDNSServers += ($_.split("="))[1] } }

#DNS Suffix Search List
$Global:arrDNSSuffixList = @()
Get-Content $configIni | foreach-object { if (($_.split("="))[0] -eq "DNSSUffixSearch") { $Global:arrDNSSuffixList += ($_.split("="))[1] } }

#Local Admin Password
Get-Content $configIni | foreach-object { if (($_.split("="))[0] -eq "AdminPassword") { $Global:AdminPassword = ($_.split("="))[1] } }

#Guest Account Rename
Get-Content $configIni | foreach-object { if (($_.split("="))[0] -eq "GuestAccount") { $Global:GuestAccount = ($_.split("="))[1] } }

#Guest Account Password
Get-Content $configIni | foreach-object { if (($_.split("="))[0] -eq "GuestPassword") { $Global:GuestPassword = ($_.split("="))[1] } }

#Boot Menu Time Out
$Global:BootTimeOut = 0
Get-Content $configIni | foreach-object { if (($_.split("="))[0] -eq "BootTimeOut") { $Global:BootTimeOut = ($_.split("="))[1] } }

#Configure KMS Client
Get-Content $configIni | foreach-object { if (($_.split("="))[0] -eq "KMSClient") { $Global:bKMSClient = ($_.split("="))[1] } }
if ($Global:bKMSClient -ieq "Yes") {$Global:bKMSClient = $true} else {$Global:bKMSClient=$false}

#Initially, set a global varibable $RebootRequired to 0 (meaning not required)
$Global:RebootRequired = 0

#start excuting build scripts

.\1_OSConfig.PS1
.\2_network.PS1
.\3_security.PS1

##End of script
$error.clear()
EndMsg $thisScript

##**Display error result**
if ($Global:ErrorDetected -eq 0){
Write-Host "No error detected while running the build scripts." -ForegroundColor $Global:OnScreenMsgColor
} elseif ($Global:ErrorDetected -eq 1) {
Write-Host "Error detected while running build scripts. Please check the $logfile for details." -ForegroundColor $Global:ErrorColor
}
Write-Host ""

##**Display Reminders**
$arrReminder = @( )
$arrReminder += "If you have action items from your build doco that are not included in this set of scripts, please go through them now."
foreach ($entry in $arrReminder)
{
	Write-Host "** $entry" -foregroundcolor $Global:OnScreenMsgColor
	Write-Host ""
}


#If reboot is required, reboot the computer
if ($Global:RebootRequired -eq 1)
{	$reboot = UserInput "Reboot required, press any key to reboot or press 'ESC' key to cancel reboot: " 2
	if ($reboot.VirtualKeyCode -ne 27)
	{
		#Start logging
		if ($error.count -ne 0) { $Global:ErrorDetected = 1; for ($i = 1; $i -le $error.count; $i++) { $logentry = $error[$error.count - $i] ; logging $thisScript $logentry 1 } } else { logging $thisScript "System Reboot initiated" 2 }
		$error.clear()
		#End logging
		$objReboot = Get-WmiObject Win32_OperatingSystem
		$objReboot.psbase.Scope.Options.EnablePrivileges = $true
		$objReboot.reboot() | Out-null
	}
	else
	{
		#Start logging
		if ($error.count -ne 0) { $Global:ErrorDetected = 1; for ($i = 1; $i -le $error.count; $i++) { $logentry = $error[$error.count - $i] ; logging $thisScript $logentry 1 } } else { logging $thisScript "System reboot aborted! Please reboot manually." 2 }
		$error.clear()
		#End logging
	}
}