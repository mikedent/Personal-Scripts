#=========================================================================================
# AUTHOR:  Tao Yang 
# DATE:    10/09/2010
# Version 2.5
# COMMENT: Windows 2008 Server Build Automated script - Operating System Configuration.
#
# Change Log	- 19/01/2009: 	Added Configuring Power Option to "High Performace"
# Change Log	- 19/01/2009:	Added Windows KMS client config and activation
# Change Log	- 10/06/2009: 	Disabled User Account Control (UAC)
# Change Log	- 16/06/2009: 	Disabled hibernation if C:\hiberfil.sys is detected.
# Change Log	- 02/09/2009: 	Modified the section for screensaver settings to include
#								both HKey_Users and HKey_Current_User
# Change Log	- 03/09/2009: 	Added Time Zone configuration
# Change Log	- 14/09/2009: 	Modified Regional setting configuration
#								In Win7 and 2008 R2, get-culture is not updated in the
#								current powershell instance.
# Change Log	- 10/09/2010: 	Enhanced time zone configuration, moved KMS config to
#								3_Security.ps1 since it requires network connectivity.
#=========================================================================================

# Clear $error
$error.clear()
#$errorActionPreference = "SilentlyContinue"
$logentry = ""

$strComputer = "."
#Determine the file system path of this script
$thisScript = Split-Path $myInvocation.MyCommand.Path -Leaf
$scriptRoot = Split-Path (Resolve-Path $myInvocation.MyCommand.Path)
#File Path for GlobalSettings script (which is located on the same folder of this script)
$GlobalSettings = $scriptRoot + "\0_GlobalSettings.PS1"
$sh = New-Object -comobject "wscript.shell"
#Load Global Settinsg
. $GlobalSettings
	#Start logging
	if ($error.count -ne 0) { $Global:ErrorDetected = 1; for ($i = 1; $i -le $error.count; $i++) { $logentry = $error[$error.count - $i] ; logging $thisScript $logentry 1 } } else	{logging $thisScript "$thisScript Initiation Completed." 0}
	$error.clear()
	#End logging
##**Scripts above this line needs to be on top of each build script.**

#Rename Computer
$newName = UserInput "Please enter a new name for this computer (Press Enter to skip)" 1
Write-Host ""
if ($newName.Length -ne 0) 
{
	$oldName = (Get-WmiObject Win32_ComputerSystem).Name
	(Get-WmiObject Win32_ComputerSystem).Rename($newName) | Out-Null
	Write-Host "**Note: Computer needs to be rebooted for the new name to take effect." -foregroundcolor $Global:OnScreenMsgColor
	Write-Host ""
	$Global:RebootRequired = 1
	#Start logging
		if ($error.count -ne 0) { $Global:ErrorDetected = 1; for ($i = 1; $i -le $error.count; $i++) { $logentry = $error[$error.count - $i] ; logging $thisScript $logentry 1 } } else { logging $thisScript "Computer Name will be changed from $oldName to $newName after reboot." 0 }
		$error.clear()
	#End logging
}
else
{
	#Start logging
	if ($error.count -ne 0) { $Global:ErrorDetected = 1; for ($i = 1; $i -le $error.count; $i++) { $logentry = $error[$error.count - $i] ; logging $thisScript $logentry 1 } } else { logging $thisScript "Computer name unchanged." 2 }
	$error.clear()
	#End logging
}

#**Windows Licensing**
#Windows Name and Organisation
$regkeypath="HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
Set-ItemProperty -Path $regkeypath -Name "RegisteredOrganization" -Value $Global:RegisteredOrg
Set-ItemProperty -Path $regkeypath -Name "RegisteredOwner" -Value $Global:RegisteredOwner
	#Start logging
	if ($error.count -ne 0) { $Global:ErrorDetected = 1; for ($i = 1; $i -le $error.count; $i++) { $logentry = $error[$error.count - $i] ; logging $thisScript $logentry 1 } } else { logging $thisScript "OS Name and Organization set." 0 }
	$error.clear()
	#End logging
	
#**Startup and Recovery Options**
$regkeypath="HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl"
#Write Debugging Info
Set-ItemProperty -Path $regkeypath -Name "CrashDumpEnabled" -Value 3
#System Failure Auto Reboot
Set-ItemProperty -Path $regkeypath -Name "AutoReboot" -Value 3
#System Failure Write to Event Logs
Set-ItemProperty -Path $regkeypath -Name "LogEvent" -Value 3
	#Start logging
	if ($error.count -ne 0) { $Global:ErrorDetected = 1; for ($i = 1; $i -le $error.count; $i++) { $logentry = $error[$error.count - $i] ; logging $thisScript $logentry 1 } } else { logging $thisScript "Startup and Recovery Option Configured." 0 }
	$error.clear()
	#End logging

#** Disable Services**
$regkeypath = "HKLM:\System\CurrentControlSet\Services\"
#For services detail, use get-service cmdlet
#Disable each service from the array
$Global:DisabledServices | foreach-Object {Set-ItemProperty -Path $regkeypath$_ -Name "Start" -Value 4}
	#Start logging
	if ($error.count -ne 0) { $Global:ErrorDetected = 1; for ($i = 1; $i -le $error.count; $i++) { $logentry = $error[$error.count - $i] ; logging $thisScript $logentry 1 } } else { logging $thisScript "Disabled services configured." 0 }
	$error.clear()
	#End logging

#**Enable Remote Desktop**
$regkeypath = "HKLM:\System\CurrentControlSet\Control\Terminal Server"
Set-ItemProperty -Path $regkeypath -Name "fDenyTSConnections" -Value 0
$regkeypath = "HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp"
Set-ItemProperty -Path $regkeypath -Name "MinEncryptionLevel" -Value 3
	#Start logging
	if ($error.count -ne 0) { $Global:ErrorDetected = 1; for ($i = 1; $i -le $error.count; $i++) { $logentry = $error[$error.count - $i] ; logging $thisScript $logentry 1 } } else { logging $thisScript "Remote Desktop configured." 0 }
	$error.clear()
	#End logging


#**MISC Settings**
#Screen Saver Password Protection
$arrRegKeyPath = @()
$arrRegkeyPath += "HKU:\.DEFAULT\Control Panel\Desktop"
$arrRegkeyPath += "HKCU:\Control Panel\Desktop"
Foreach ($regkeypath in $arrRegKeyPath)
{
	Set-ItemProperty -Path $regkeypath -Name "ScreenSaveActive" -Value "1"
	Set-ItemProperty -Path $regkeypath -Name "ScreenSaverIsSecure" -Value "1"
	Set-ItemProperty -Path $regkeypath -Name "SCRNSAVE.EXE" -Value $Global:ScreenSaverName
}
$arrRegKeyPath = $null


#Standard Desktop -Logon Screen Saver Timeout Time - in seconds
Set-ItemProperty -Path $regkeypath -Name "ScreenSaveTimeout" -Value $Global:ScreenSaverTimeout

	#Start logging
	if ($error.count -ne 0) { $Global:ErrorDetected = 1; for ($i = 1; $i -le $error.count; $i++) { $logentry = $error[$error.count - $i] ; logging $thisScript $logentry 1 } } else { logging $thisScript "Screen Saver configured." 0 }
	$error.clear()
	#End logging

#Force Classic Start Menu
$regkeypath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\policies\Explorer"
#Create the key if doesn't exist (by default in Windows 7)
if (!(Test-Path $regkeypath)) {New-Item $regkeypath | Out-Null}
if ((Get-ItemProperty -Path $regkeypath).NoSimpleStartMenu -eq $null)
{ New-ItemProperty $regkeypath -Name "NoSimpleStartMenu" -type DWORD | Out-Null}
Set-ItemProperty -Path $regkeyPath -Name "NoSimpleStartMenu" -Value 1
	#Start logging
	if ($error.count -ne 0) { $Global:ErrorDetected = 1; for ($i = 1; $i -le $error.count; $i++) { $logentry = $error[$error.count - $i] ; logging $thisScript $logentry 1 } } else { logging $thisScript "Classic Startup Menu configured." 0 }
	$error.clear()
	#End logging

##Standard Desktop -Window Animations
$regkeypath = "HKU:\.DEFAULT\Control Panel\Desktop\WindowMetrics"
$regkeyexists = Test-Path $regkeypath
if ($regkeyexists -eq $false)
{ New-Item -Path $regkeypath | Out-Null }

if ((Get-ItemProperty -Path $regkeypath).minAnimate -eq $null)
{ New-ItemProperty $regkeypath -Name "minAnimate" -type DWORD | Out-Null}
Set-ItemProperty -Path $regkeyPath -Name "minAnimate" -Value 0
	#Start logging
	if ($error.count -ne 0) { $Global:ErrorDetected = 1; for ($i = 1; $i -le $error.count; $i++) { $logentry = $error[$error.count - $i] ; logging $thisScript $logentry 1 } } else { logging $thisScript "Windows Animation disabled." 0 }
	$error.clear()
	#End logging

##Standard Desktop - Automatically End Hung Applications on ShutDown
$regkeypath = "HKU:\.DEFAULT\Control Panel\Desktop"
if ((Get-ItemProperty -Path $regkeypath).AutoEndTasks -eq $null)
{ New-ItemProperty $regkeypath -Name "AutoEndTasks" -type String | Out-Null}
Set-ItemProperty -Path $regkeyPath -Name "AutoEndTasks" -Value "1"
	#Start logging
	if ($error.count -ne 0) { $Global:ErrorDetected = 1; for ($i = 1; $i -le $error.count; $i++) { $logentry = $error[$error.count - $i] ; logging $thisScript $logentry 1 } } else { logging $thisScript "Enabled 'Automatically End Hung Applications on Shutdown'." 0 }
	$error.clear()
	#End logging

##Standard Desktop -My Computer Icon Matches System Name
#For Windows 2008 R2 and Windows 7, The permission of below registry key needs to be temporarily modified to make the change.

$regkeypath = "HKCR:\CLSID\{20D04FE0-3AEA-1069-A2D8-08002B30309D}"
$strSetACLPath = Join-Path $scriptRoot "SetACL\$Global:OSArchitecture\SetACL.exe"
#temporarily modify the registry key permission so we can change the value...
if ($Global:OSMajorVersion -eq "6.1")
{
	#Firstly get the current ACL
	$RegKeyOldACL = Get-Acl $regkeypath
	$RegKeyOldOwnerName = [system.security.principal.NtAccount]$RegKeyOldACL.Owner
	$RegKeyOldOwnerSID = ($RegKeyOldOwnerName.translate([system.security.principal.securityidentifier])).tostring()
	#Modify the ACL
	#Will temporarily change the owner to local Administrators group
	$RegKeyNewOwnerName = [system.security.principal.NtAccount]"BUILTIN\Administrators"
	$RegKeyNewOwnerSID = ($RegKeyNewOwnerName.translate([system.security.principal.securityidentifier])).tostring()
	
	#Due to the key is protected by Windows Resource Protection in Windows 7 and Windows 2008 R2, set-acl cmdlet does not work.
	#Therefore I'm using setacl.exe (http://setacl.sourceforge.net/) to perform this change.
	#setacl.exe (64-bit) is located in the same folder of this script
	$strRegPath = "HKCR\CLSID\{20D04FE0-3AEA-1069-A2D8-08002B30309D}"	#a format that's accepted by SetACL.EXE
	$strSetACLCmd = "`"$strSetACLPath`" -on $strRegPath -ot reg -actn setowner -ownr `"n:$RegKeyNewOwnerSID;s:y`""
	$setACL = $sh.run("$strSetACLCmd",1,"true")
	
	#Give local administrators group full access to the key
	$strSetACLCmd = "`"$strSetACLPath`" -on $strRegPath -ot reg -actn ace -ace `"n:$RegKeyNewOwnerSID;p:full;s:y`""
	#$setACL = $sh.run("$strSetACLCmd",1,"true")
	$setACL = $sh.run("$strSetACLCmd",1,"true")
}

#Modify the key value
Set-ItemProperty -Path $regkeyPath -Name "LocalizedString" -Value "%computername%"


#change the ACL back
if ($Global:OSMajorVersion -eq "6.1")
{	
	#get the old access rule for the temporary account (local administrators group) ...
	$ArrRegKeyRules = @()
	Foreach ($rule in ($RegKeyOldACL.getaccessrules($true,$true,[system.security.principal.securityidentifier])))
	{
		if ($rule.IdentityReference.tostring() -match $RegKeyNewOwnerSID)
		{
			$ArrRegKeyRules += $rule
		}
	}

	#Create a new incident of the ACL...
	$RegKeyNewACL = Get-Acl $regkeypath
	
	#Firstly remove all the access rules for the temp account (local administrators group)
	Foreach ($rule in ($RegKeyNewACL.getaccessrules($true,$true,[system.security.principal.securityidentifier])))
	{
		if ($rule.IdentityReference.tostring() -match $RegKeyNewOwnerSID)
		{
			$RegKeyNewACL.RemoveAccessRuleALL($rule)
		}
	}
	#Then add the old access rule(s) back (if there are any)
	if ($ArrRegKeyRules.count -gt 0)
	{Foreach ($rule in $arrRegKeyRules) {$RegKeyNewACL.addAccessRule($rule)}}
	#Set the permission back
	Set-Acl $regkeypath $RegKeyNewACL
	#Change the owner back
	$strSetACLCmd = "`"$strSetACLPath`" -on $strRegPath -ot reg -actn setowner -ownr `"n:$RegKeyOldOwnerSID;s:y`""
	$setACL = $sh.run("$strSetACLCmd",1,"true")	
}
	#Start logging
	if ($error.count -ne 0) { $Global:ErrorDetected = 1; for ($i = 1; $i -le $error.count; $i++) { $logentry = $error[$error.count - $i] ; logging $thisScript $logentry 1 } } else { logging $thisScript "Renamed 'My Computer' icon to computer name." 0 }
	$error.clear()
	#End logging
	
##Time Source
$regkeypath = "HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Parameters"
Set-ItemProperty -Path $regkeyPath -Name "NtpServer" -Value $Global:NTP
	#Start logging
	if ($error.count -ne 0) { $Global:ErrorDetected = 1; for ($i = 1; $i -le $error.count; $i++) { $logentry = $error[$error.count - $i] ; logging $thisScript $logentry 1 } } else { logging $thisScript "NTP time source configured." 0 }
	$error.clear()
	#End logging

##User Account Control
$regkeypath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
Set-ItemProperty -Path $regkeyPath -Name "EnableLUA" -Value 0
	#Start logging
	if ($error.count -ne 0) { $Global:ErrorDetected = 1; for ($i = 1; $i -le $error.count; $i++) { $logentry = $error[$error.count - $i] ; logging $thisScript $logentry 1 } } else { logging $thisScript "User Access Control Disabled." 0 }
	$error.clear()
	#End logging
	
##Configure Boot menu time out setting
if ($Global:BootTimeOut -gt 0)
{
	$BootTimeOut = $sh.run("bcdedit /timeout $Global:BootTimeOut",1,"true")
	#Start logging - note: different than other sections!
	if ($BootTimeOut -ne 0) { $Global:ErrorDetected = 1; $logentry = "Error configuring OS Boot Menu Time Out setting!" ; logging $thisScript $logentry 1 } else { logging $thisScript "OS Boot Menu Time Out Setting configured." 0 }
	#End logging
} else {
	#Start logging - note: different than other sections!
	$Global:ErrorDetected = 1; $logentry = "Invalid OS Boot Menu Time Out setting specified!" ; logging $thisScript $logentry 1
	#End logging
}

##Configure Power Options
$HighPerfPwrGUID = "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"
$PowerCfgCmd = "powercfg -s $HighPerfPwrGUID"
$PowerCfg = $sh.run($PowerCfgCmd, 1, "true")
	#Start logging - note: different than other sections!
	if ($PowerCfg -ne 0) { $Global:ErrorDetected = 1 ; $logentry = "Error configuring Power Scheme!" ; logging $thisScript $logentry 1 } else { logging $thisScript "Power Options configured." 0 }
	#End logging
if ((Test-Path(Join-Path $env:SystemDrive hiberfil.sys)))
	{
		$turnoffHibernationCmd = "powercfg /h off"
		$HibernationCfg = $sh.run($turnoffHibernationCmd, 1, "true")
		#Start logging - note: different than other sections!
		if ($HibernationCfg -ne 0) { $Global:ErrorDetected = 1 ; $logentry = "Error turning off hibernation!" ; logging $thisScript $logentry 1 } else { logging $thisScript "Hibernation turned off." 0 }
		#End logging
	}

## Configure Regional and Language Options
	#Logging - Check if the Locale XML config file exists
	if (!(Test-Path $Global:localeFile)) { $Global:ErrorDetected = 1; $logentry = "$LocaleXML is missing. Please make sure it is in $scriptroot directory!" ; logging $thisScript $logentry 1 } else { logging $thisScript "$Global:localeFile detected, Start configure system regional settings." 2 }
	#End logging
$LocaleCmd = "control intl.cpl,, /f:" + [char]34 + $Global:localeFile + [char]34
$sh.run($LocaleCmd, 1, "true") | Out-Null
$cultureObj = New-Object system.Globalization.CultureInfo($Global:SystemLocale)

$CultureLCID = powershell "(Get-Culture).LCID"	#in Win 7 and 2008 R2, new culture is not refreshed in current powershell session..
$CultureName = powershell "(Get-Culture).Name"	#in Win 7 and 2008 R2, new culture is not refreshed in current powershell session..
	#Logging - Check if the Locale Has been set
	if (($CultureLCID -eq $cultureObj.LCID) -and ($CultureName -eq $Global:SystemLocale)) { $logentry = "The system regional setting has been correctly configured." ; logging $thisScript $logentry 0 } else { $Global:ErrorDetected = 1; logging $thisScript "Incorrect Regional setting detected, Regional setting configuration failed." 1 }
	#End logging
	
	#Logging - Check if Reboot is required
	if (($CultureLCID -ne $Global:oldCultureLCID) -or ($CultureName -ne $Global:oldCultureName)) { $logentry = "System needs to be rebooted for the regional setting to take effect." ; logging $thisScript $logentry 2; Write-Host "**Note: System needs to be rebooted for the regional setting to take effect." -foregroundcolor $Global:OnScreenMsgColor; Write-Host ""; $Global:RebootRequired = 1 }
	#End logging
	
## Configure Time Zone settings
#**note: the time zone config scripts are downloaded from here:
# http://blogs.technet.com/deploymentguys/archive/2009/06/07/setting-the-time-zone-using-windows-powershell.aspx
$TimeZoneRootKey = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Time Zones"

$strTZLog = $null

$bConfigTZ = UserInput "Please press any key to configure Time Zone settings or press ESC to skip" 2
Write-Host ""
if ($bConfigTZ.VirtualKeyCode -ne 27)
	{
		$arrTimezones = @()

		Foreach ($item in Get-ChildItem $TimeZoneRootKey)
		{
			$objTZ = New-Object psobject
			Add-Member -InputObject $objTZ -membertype noteproperty -name Name -value $item.PSChildName
			Add-Member -InputObject $objTZ -membertype noteproperty -name DisplayName -value $item.GetValue("Display")
			$arrTimezones += $objTZ
		}
		$arrTimezones = $arrTimezones | Sort-Object DisplayName
		
		Write-Host "Please choose the timezone from the following list:" -ForegroundColor $Global:UserInputColor
		Write-Host "===================================================" -ForegroundColor $Global:UserInputColor
		For ($i=1; $i -le $arrTimezones.count; $i++) {
			$strTimeZoneDisplayName = $arrTimezones[($i-1)].DisplayName
			Write-Host "$i - $strTimeZoneDisplayName" -ForegroundColor $Global:UserInputColor
		}
		Write-Host "===================================================" -ForegroundColor $Global:UserInputColor
		Write-Host ""
		$iTimeZone = UserInput "Please choose the time zone or Press Enter to cancel" 1
		Write-Host ""
		if ($iTimeZone -ge 1 -and $iTimeZone -le $arrTimezones.count)
		{
		$strTimeZone = $arrTimezones[($iTimeZone-1)].Name
		Write-Host "Setting time zone to $strTimeZone..." -foregroundcolor $Global:OnScreenMsgColor
		$TSScript = join-path (join-path $scriptRoot "PSTimeZoneScripts") "Set-TimeZone.ps1"
		#check existance of the time zone scripts
		if (Test-Path $TSScript)
		{
			if ($strTimeZone -ne $null)
			{
				#Powershell.exe -NoProfile -command "& {$TSScriptFolder\Set-TimeZone.ps1 -name $strTimeZone}" -noexit
				switch ($Global:OSMajorVersion)
				{
				6.0 {. $TSScript -name $strTimeZone}
				6.1 { tzutil /s `"$strTimeZone`"}
				}
				$StrCurrentTZ = (Get-WmiObject win32_timezone).StandardName
				if ($StrCurrentTZ -match $strTimeZone)
				{
					#Timezone is successfully changed
					$strTZLog = "The Time Zone has been changed to $strTimeZone."
				} else {
					Write-Error "Error: Time zone has not been changed from $StrCurrentTZ to $strTimeZone" 2>&1 | Out-Null
				}
				
			} else {
				Write-Error "No Time Zone specified. please manually change it if required." 2>&1 | Out-Null
			}
			
		} else {
			Write-Error "Error: The PSTimeZoneScripts folder does not exist. please place it under the Build Script folder"
		}
		}else {
			#Start logging
			$Global:ErrorDetected = 1 ; $logentry = "Invalid Time Zone selected!" ; $error.add("Time Zone is not configured!"); logging $thisScript $logentry 1
			#End logging
		}
			#Start logging
			if ($error.count -ne 0) { $Global:ErrorDetected = 1 ; for ($i = 1; $i -le $error.count; $i++) { $logentry = $error[$error.count - $i] ; logging $thisScript $logentry 1 } } else { logging $thisScript $strTZLog 0 }
			$error.clear()
			#End logging
	} 
##End of script
$error.clear()
EndMsg $thisScript