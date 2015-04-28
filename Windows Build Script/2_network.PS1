#======================================================================================
# AUTHOR:  Tao Yang 
# DATE:    10/09/2010
# Version 2.5
# COMMENT: Windows 2008 Server Build Automated script - Network Configuration.
# UPDATE: 22/04/2009 - corrected Disabling IPV6 section
# UPDATE: 09/09/2010 - Added function to configure IP addresses.
#======================================================================================
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

#Start logging
if ($error.count -ne 0) { $Global:ErrorDetected = 1; for ($i = 1 ; $i -le $error.count ; $i++) { $logentry = $error[$error.count - $i]; logging $thisScript $logentry 1 }} else { logging $thisScript "$thisScript Initiation Completed." 0 }
$error.clear()
#End logging
##**Scripts above this line needs to be on top of each build script.**

#**Configuring Network Connections**
$intUnused = 1
$intUsed = 1
$sh = New-Object -comobject "wscript.shell"

$colConn = Get-WmiObject -Query "Select * from Win32_NetworkAdapter where AdapterType LIKE 'Ethernet%'"

#Start logging
if ($error.count -ne 0) { $Global:ErrorDetected = 1; for ($i = 1; $i -le $error.count; $i++) { $logentry = $error[$error.count - $i] ; logging $thisScript $logentry 1 } } else { logging $thisScript "Connected to WMI repository, Start configuring Network Connections." 2 }
$error.clear()
#End logging

$iUnconfiguredNetwork = 0
$colConn | foreach-Object {

	if ($_.netConnectionStatus -eq 2)
	{
		if ((($_.netConnectionID).ToLower()).contains("local area connection"))
		{
			$strOldName = $_.netConnectionID
			#Configure IP addresses
			$bConfigIP = UserInput "Please press any key to configure static IP address for $strOldName or press ESC to skip" 2
			Write-Host ""
			if ($bConfigIP.VirtualKeyCode -ne 27)
			{
				$arrInvalidNetworkInput = @()
				$strIP = UserInput "IP address (Press Enter to skip)	" 1
				$strSubnetMask = UserInput "Subnet Mask (Press Enter to skip)	" 1
				$strGateway = UserInput "Default Gateway (Press Enter to skip)	" 1
				
				$bValidIP = validateIP($strIP)
				if (!($bValidIP)) {$arrInvalidNetworkInput += "Invalid IP Address Entered!"}
				
				$bValidSubNetMask = validateSubnetMask($strSubnetMask)
				if (!($bValidSubNetMask)) {$arrInvalidNetworkInput += "Invalid Subnet Mask Entered!"}
				
				$bValidGateway = validateIP($strGateway)
				if (!($bValidGateway)) {$arrInvalidNetworkInput += "Invalid Default Gateway Address Entered!"}
				
				If ($arrInvalidNetworkInput.count -eq 0)
				{
					SetIP $_.MACAddress $strIP $strSubnetMask $strGateway
				} else {
					foreach ($item in $arrInvalidNetworkInput) {$error.Add($item)|Out-Null}
				}
				#Start logging
				if ($error.count -ne 0) { $Global:ErrorDetected = 1; for ($i = 1; $i -le $error.count; $i++) { $logentry = $error[$error.count - $i] ; logging $thisScript $logentry 1 } } else { logging $thisScript "Network Connection $strOldName has been renamed to $strNewName." 0 }
				$error.clear()
				#End logging
			}
			
			# Rename active connection
			$strOldName = $_.netConnectionID
			$strIP = GetIP $_.MACAddress
			$strSubnetMask = GetSubnetMask $_.MACAddress
			if ((validateIP($strIP)) -and (validateSubnetMask($strSubnetMask)))
			{
				$strNetwork = GetNetwork $strIP $strSubnetMask
				$strNewName = "Active_#" + $intUsed + "_" + $strNetwork
			} else {
				$iUnconfiguredNetwork ++
				$strNewName = "Unconfigured_#" + $iUnconfiguredNetwork
			}
			RenameNetConn $strOldName $strNewName
			$intUsed++
			#Start logging
			if ($error.count -ne 0) { $Global:ErrorDetected = 1; for ($i = 1; $i -le $error.count; $i++) { $logentry = $error[$error.count - $i] ; logging $thisScript $logentry 1 } } else { logging $thisScript "Network Connection $strOldName has been renamed to $strNewName." 0 }
			$error.clear()
			#End logging
		}
										
	}
	elseif ($_.netConnectionStatus -eq 7)
	{
		if ((($_.netConnectionID).ToLower()).contains("local area connection"))
		{
			$strOldName = $_.netConnectionID
			$strNewName = "Unused_#" + $intUnused
			RenameNetConn $strOldName $strNewName
			#Start logging
			if ($error.count -ne 0) {$Global:ErrorDetected = 1;  for ($i = 1; $i -le $error.count; $i++) { $logentry = $error[$error.count - $i] ; logging $thisScript $logentry 1 } } else { logging $thisScript "Network Connection $strOldName has been renamed to $strNewName." 0 }
			$error.clear()
			#End logging
		}
		else
		{
			$strNewname = $_.netConnectionID
		}
		#This might be a bug in Windows 2008, when netconnectionID = 7 (disconnected), the connection cannot be disabled.
		#When it's connected (netconnectionID = 2), disable() method works perfectly.
		#$_.Disable()
		$strCmd = "netsh interface set interface " + [char]34 + $strNewName + [char]34 + " Disable"
		$sh.run($strCmd,1,"true") | Out-Null 
		#Start logging
		if ($error.count -ne 0) { $Global:ErrorDetected = 1; for ($i = 1; $i -le $error.count; $i++) { $logentry = $error[$error.count - $i] ; logging $thisScript $logentry 1 } } else { logging $thisScript "Disabled Un-used Network Connection $strNewName." 0 }
		$error.clear()
		#End logging
		$intUnused++
						
	}
}

#DNS Server List
if ($Global:arrDNSServers.count -gt 0)
{
	$Nics = Get-WmiObject -query "SELECT * FROM Win32_NetworkAdapterConfiguration WHERE IPEnabled = True"
	$Nics | foreach-object { $_.SetDNSServerSearchOrder($Global:arrDNSServers) | Out-Null }
	#Start logging
	if ($error.count -ne 0) { $Global:ErrorDetected = 1; for ($i = 1; $i -le $error.count; $i++) { $logentry = $error[$error.count - $i] ; logging $thisScript $logentry 1 } } else { logging $thisScript "DNS server list is set." 0 }
	$error.clear()
	#End logging
}

#DNS Suffix Search Order
if ($Global:arrDNSSuffixList.count -gt 0)
{
	$objNetworkSettings = [wmiclass] "win32_networkadapterconfiguration"
	$objNetworkSettings.SetDNSSuffixSearchOrder($Global:arrDNSSuffixList) | Out-Null
	#Start logging
	if ($error.count -ne 0) { $Global:ErrorDetected = 1; for ($i = 1; $i -le $error.count; $i++) { $logentry = $error[$error.count - $i] ; logging $thisScript $logentry 1 } } else { logging $thisScript "DNS Suffix Search List is set." 0 }
	$error.clear()
	#End logging
}

##Disable LMHosts Lookup
$regkeypath = "HKLM:\System\CurrentControlSet\Services\NetBT\Parameters"
Set-ItemProperty -Path $regkeyPath -Name "EnableLMHOSTS" -Value 0
	#Start logging
	if ($error.count -ne 0) { $Global:ErrorDetected = 1; for ($i = 1; $i -le $error.count; $i++) { $logentry = $error[$error.count - $i] ; logging $thisScript $logentry 1 } } else { logging $thisScript "LMHosts Lookup disabled." 0 }
	$error.clear()
	#End logging

##Show Network Connection Icon in Sys Tray - Windows 6.0 only
if ($Global:OSMajorVersion -eq "6.0") {
	$regkeypath = "HKLM:\System\CurrentControlSet\Control\Network\{4D36E972-E325-11CE-BFC1-08002BE10318}"
	$arrsubkeys = Get-ChildItem $regkeypath
	$arrsubkeys | foreach-Object {
		if ($_.PSChildname -ne "Descriptions")
		{
			$regsubpath = Join-Path $regkeypath $_.PSChildName
			if ((Get-ItemProperty -Path(Join-Path $regsubpath Connection -resolve)).ShowIcon -eq $null)
			{ New-ItemProperty(Join-Path $regsubpath Connection -resolve) -Name "ShowIcon" -type DWORD | Out-Null}
			Set-ItemProperty -Path(Join-Path $regsubpath Connection -resolve) -Name "ShowIcon" -Value 1
		}
	}
	#Start logging
	if ($error.count -ne 0) { $Global:ErrorDetected = 1; for ($i = 1; $i -le $error.count; $i++) { $logentry = $error[$error.count - $i] ; logging $thisScript $logentry 1 } } else { logging $thisScript "Show Network Connection Icon configured for all active NICs." 0 }
	$error.clear()
	#End logging
} else {
	#Start logging
	logging $thisScript "'Show Network Connection Icon in System Tray' is not supported for this Operating System: $Global:OSCaption." 2
	#End logging
}


##Disable IPV6
$regkeypath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters"
$regvalue = 4294967295
if ((Get-ItemProperty -Path $regkeypath).DisabledComponents -eq $null)
{ New-ItemProperty $regkeypath -Name "DisabledComponents" -type DWORD | Out-Null}

if ((Get-ItemProperty -Path $regkeypath).DisabledComponents -ne $regvalue)
{Set-ItemProperty -Path $regkeyPath -Name "DisabledComponents" -Value $regvalue
	$Global:RebootRequired = 1
	#HOSTS file needs to be modified as well
	$arrHostsFile = New-Object System.Collections.Arraylist
	$strLineToDelete = "::1             localhost"
	#read the Hosts File
	$arrTemp = Get-Content $env:systemroot\system32\drivers\etc\hosts
		
	#convert the array from a powershell array to .NET array
	foreach ($item in $arrTemp)
		{ $arrHostsFile.Add($item) | Out-Null }
	$arrHostsFile.remove($strLineToDelete)
		
	#Write modifed HOST file back to the actual file
	$arrhostsfile | Set-Content $env:systemroot\system32\drivers\etc\hosts -force
	
	Write-Host "**Note: Computer needs to be rebooted after disabling IPV6." -foregroundcolor $Global:OnScreenMsgColor
	Write-Host ""
}
	#Start logging
	if ($error.count -ne 0) { $Global:ErrorDetected = 1; for ($i = 1; $i -le $error.count; $i++) { $logentry = $error[$error.count - $i] ; logging $thisScript $logentry 1 } } else { logging $thisScript "IPV6 Disabled." 0 }
	$error.clear()
	#End logging

##End of script
$error.clear()
EndMsg $thisScript
