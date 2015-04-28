#===============================================================================================
# AUTHOR:  Tao Yang 
# DATE:    10/09/2010
# Version 2.5
# COMMENT: Windows 2008 Server Build Automated script - Operating System Security Configuration.
#===============================================================================================
# Clear $error
$error.clear()
$errorActionPreference = "SilentlyContinue"
$logentry = ""
$strComputer = "."
$sh = New-Object -comobject "Wscript.Shell"
#Determine the file system path of this script
$thisScript = Split-Path $myInvocation.MyCommand.Path -Leaf
$scriptRoot = Split-Path(Resolve-Path $myInvocation.MyCommand.Path)
#File Path for GlobalSettings script (which is located on the same folder of this script)
$GlobalSettings = $scriptRoot + "\0_GlobalSettings.PS1"

#Load Global Settinsg
. $GlobalSettings

#Start logging
if ($error.count -ne 0) { $Global:ErrorDetected = 1; for ($i = 1; $i -le $error.count; $i++) { $logentry = $error[$error.count - $i] ; logging $thisScript $logentry 1 } } else { logging $thisScript "$thisScript Initiation Completed." 0 }
$error.clear()
#End logging
##**Scripts above this line needs to be on top of each build script.**

##Configure builtin accounts

$ColAccounts = Get-WmiObject Win32_UserAccount -filter "domain='$env:computername'"

#**Reset Local adminsitrator password
$bChangeAdminPw = UserInput "Please press any key to change the Built-In administrator account password or press ESC to skip:" 2
Write-Host ""

if ($bChangeAdminPw.VirtualKeyCode -ne 27)
{
	$strAdminPassword = ConvertTo-SecureString $Global:AdminPassword -AsPlainText -force
	$strAdminPw = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($strAdminPassword))
	$ColAccounts | foreach-object { 
		if (($_.SID.substring(0, 8) -match "S-1-5-21") -and ($_.SID.substring($_.SID.length-3, 3) -match "500"))
		{	#Set password
			$computer = [ADSI] "WinNT://$env:computername,computer"
			$objAdmin = $computer.psbase.children.Find($_.name)
			$objAdmin.SetPassword($strAdminPw)
		}
	}
}
	#Start logging
	if ($error.count -ne 0) { $Global:ErrorDetected = 1; for ($i = 1; $i -le $error.count; $i++) { $logentry = $error[$error.count - $i] ; logging $thisScript $logentry 1 } } else { logging $thisScript "The password of the local admin account has been set." 0 }
	$error.clear()
	#End logging
	
#**Configure Guest account**
$strGuestPassword = ConvertTo-SecureString $Global:GuestPassword -AsPlainText -force
$strGuestPw = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($strGuestPassword))
$ColAccounts | foreach-object { 
	if (($_.SID.substring(0, 8) -match "S-1-5-21") -and ($_.SID.substring($_.SID.length-3, 3) -match "501"))
	{	#Set password
		$computer = [ADSI] "WinNT://$env:computername,computer"
		$objGuest = $computer.psbase.children.Find($_.name)
		$objGuest.SetPassword($strGuestPw)
		#$objGuest.psbase.CommitChanges()
		#Disable
		$_.disabled = $true
		$_.put() | Out-Null

	}
}
	#Start logging
	if ($error.count -ne 0) { $Global:ErrorDetected = 1; for ($i = 1; $i -le $error.count; $i++) { $logentry = $error[$error.count - $i] ; logging $thisScript $logentry 1 } } else { logging $thisScript "Guest account renamed, disabled and the password has been set." 0 }
	$error.clear()
	#End logging
	
	
##**Configure Security Policy**

$SecTemplate = Join-Path $scriptRoot "SecPolicy.inf" -Resolve
	#Start logging
	if ($error.count -ne 0) { $Global:ErrorDetected = 1; for ($i = 1; $i -le $error.count; $i++) { $logentry = $error[$error.count - $i] ; logging $thisScript $logentry 1 } } else { logging $thisScript "Security Template $SecTemplate located. Processing..." 2 }
	$error.clear()
	#End logging

$SecDB = Join-Path $scriptRoot "SecDB.db"
$SecLog = Join-Path $scriptRoot "security.log"
#Remove old db and log file if exist.
if (Test-Path $SecDB) { Remove-Item $SecDB }
if (Test-Path $SecLog) { Remove-Item $SecLog }
	#Start logging
	if ($error.count -ne 0) { $Global:ErrorDetected = 1; for ($i = 1; $i -le $error.count; $i++) { $logentry = $error[$error.count - $i] ; logging $thisScript $logentry 1 } } else { logging $thisScript "Old Security Database $SecDB deleted." 2 }
	$error.clear()
	#End logging

$SecEditCmd = "secedit /configure /db " + [char]34 + $SecDB + [char]34 + " /cfg " + [char]34 + $SecTemplate + [char]34 + " /log " + [char]34 + $SecLog + [char]34 + " /verbose /quiet"
$SecConfig = $sh.Run($SecEditCmd, 1, "true")
#Start logging - note: different than other sections!
if ($SecConfig -ne 0) { $Global:ErrorDetected = 1; $logentry = "Error performing security configuration!" ; logging $thisScript $logentry 1 } else { logging $thisScript "Security Template successfully imported. Please refer to Security.log for details." 0 }
$error.Clear()
#End logging

##**Disable Windows Firewall**
$firewallCmd = "netsh advfirewall set allprofiles state off"
$firewall = New-Object -com HNetCfg.FwMgr
if ($firewall.LocalPolicy.CurrentProfile.FirewallEnabled -eq $true)
{ $sh.run($firewallCmd,1,"true") | Out-Null}

		#Start logging
		if ($firewall.LocalPolicy.CurrentProfile.FirewallEnabled -eq $true) { $Global:ErrorDetected = 1; $logentry = "Error disabling Windows Firewall" ; logging $thisScript $logentry 1 } else { logging $thisScript "Windows Firewall disabled." 0 }
		$error.clear()
		#End logging

###**ConfigureLMCompatibilityLevel - For Windows 7 and Windows Server 2008 R2 only
##http://technet.microsoft.com/es-es/magazine/2006.08.securitywatch(en-us).aspx
#if ($Global:OSMajorVersion -eq "6.1") {
#	$regkeypath = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"
#	if ((Get-ItemProperty -Path $regkeypath).LMCompatibilityLevel -eq $null)
#	{ New-ItemProperty $regkeypath -Name "LMCompatibilityLevel" -type DWORD | Out-Null}
#	Set-ItemProperty -Path $regkeyPath -Name "LMCompatibilityLevel" -Value 1
#		#Start logging
#		if ($error.count -ne 0) { $Global:ErrorDetected = 1; for ($i = 1; $i -le $error.count; $i++) { $logentry = $error[$error.count - $i] ; logging $thisScript $logentry 1 } } else { logging $thisScript "LMCompatibilityLevel is set to 1 (Send LM and NTLM—use NTLMv2 session security if negotiated)." 0 }
#		$error.clear()
#		#End logging
#}

##**Activate Windows**
If ($Global:bKMSClient -eq $true)
{
	#Windows Licensing - KMS
	$activeLicense = Get-WmiObject SoftwareLicensingProduct -filter "LicenseStatus <> '0'"
	$LicType = "VOLUME_KMSCLIENT"
	if (($activeLicense.GetType()).IsArray -eq $true)
	{
		#Multiple active license detected
		$Global:ErrorDetected = 1 ; $logentry = "Multiple Windows license detected!" ; logging $thisScript $logentry 1 
	}
	else
	{
		if ($activeLicense.LicenseStatus -ne "1" -or $activeLicense.description -notmatch $LicType)
		{
			$objLicService = Get-WmiObject SoftwareLicensingService
			$KMSSetupKey = GetKMSSetupKey $Global:OSSKU $Global:OSMajorVersion
			if ($KMSSetupKey -ne $null)
			{
				$objLicService.InstallProductKey($KMSSetupKey) | Out-Null
				#Start logging
				if ($error.count -ne 0) { $Global:ErrorDetected = 1 ; for ($i = 1; $i -le $error.count; $i++) { $logentry = $error[$error.count - $i] ; logging $thisScript $logentry 1 } } else { logging $thisScript "Default KMS Client Install Key Installed." 0 }
				$error.clear()
				#End logging
				$activeLicense = Get-WmiObject SoftwareLicensingProduct -filter "LicenseStatus <> '0'"
				$objLicService.RefreshLicenseStatus() | Out-Null
				$activeLicense.Activate() | Out-Null
				#Start logging
				if ($error.count -ne 0) { $Global:ErrorDetected = 1 ; for ($i = 1; $i -le $error.count; $i++) { $logentry = $error[$error.count - $i] ; logging $thisScript "KMS Activation error: $logentry" 1 } } else { logging $thisScript "Windows has been successfully activated." 0 }
				$error.clear()
				#End logging
			}
			else
			{
				$Global:ErrorDetected = 1 ; $logentry = "Error determining default KMS Client Setup Key for this operating System!" ; logging $thisScript $logentry 1 
			}
		}
	}
}
##End of script
$error.clear()
EndMsg $thisScript