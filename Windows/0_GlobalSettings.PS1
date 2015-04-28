#=========================================================================================================
# AUTHOR:  Tao Yang 
# DATE:    10/09/2010
# Version: 2.5
# COMMENT: Windows 2008 Server (R2) Build Automated script - Global Settings and function library
#
# Change Log	- 19/01/2009:	Added GetKMSSetupKey function
# Change Log	- 01/09/2009: 	Modified GetKMSSetupKey function to include Windows Server 2008 R2 keys.
# Change Log	- 03/09/2009:	Added fixed the bug in UserInput function
# Change Log	- 08/09/2009:	Added KMS keys for Windows Vista and Windows 7
# Change Log	- 11/09/2009:	Fixed UserInput function, renamed variable $input to $strInput as $input
#								is researved.
# Change Log	- 10/09/2010:	Added SetIP and Get-GEOID functions.
#=========================================================================================================

	#Foreground and Background color
	$host.ui.rawui.foregroundcolor = $Global:fgColor
	$host.ui.rawui.backgroundColor = $Global:bgColor

	#Window Title
$host.ui.rawui.WindowTitle = $Global:Title

##Check if HKCR and HKU already added in this instance
Get-PSDrive | foreach-object {if ($_.name -match "HKU") {$HKU = 1}}
Get-PSDrive | foreach-object {if ($_.name -match "HKCR") {$HKCR = 1}}

##Add HKCR and HKU if not already added
if ($HKCR -ne 1) {
	New-PSDrive -name HKCR -PsProvider registry -Root HKEY_CLASSES_ROOT | Out-Null
}

if ($HKU -ne 1)
{
	New-PSDrive -name HKU -PsProvider registry -Root HKEY_USERS | Out-Null
}

#Determine the file system path of this script
$scriptRoot = Split-Path(Resolve-Path $myInvocation.MyCommand.Path)
$logfilename = "BuildLog.log"
$logfile = Join-Path $scriptRoot $logfilename
$Global:localeFile = Join-Path $scriptRoot "locale.xml"



function logging($strScriptName, $strlogs, $intStatus)
{
	#Create the log file if it doesn't exist
	if (!(Test-Path $logfile))
	{
		New-Item -Path $scriptRoot -Name $logfilename -type file | Out-Null
		Add-Content "**Windows Server 2008, 2008 R2 and Windows 7 Build Scripts Log File**" -path $logfile
		Add-Content "***************************************" -path $logfile
	}
	$strTime = (Get-Date).ToString()
	switch($intStatus)
	{
	0 { $strStatus = "Success:" }
	1 { $strStatus = "Fail:   " }
	2 { $strStatus = "Info:   " }
	default { $strStatus = "Info:"}
	}
	
	
	Add-Content "$strStatus <$strTime> From <$strScriptName>: $strlogs " -path $logfile
}

function EndMsg($strScriptname)
{
	Write-Host "$strScriptname has been executed! Please check the log for details." -Foregroundcolor $Global:OnScreenMsgColor
	Write-Host ""
}

function Get-GEOID ($strCulture)
{
	$arrCultures = New-Object System.Collections.ArrayList
	$AllCultures = [System.Globalization.CultureTypes]::AllCultures
	foreach ($culture in ([System.Globalization.CultureInfo]::GetCultures($AllCultures))) {$arrCultures.add($culture.name.tolower()) | Out-Null}
	
	#if Culture is invalid, use the current culture - this means the system culture is UNCHANGED
	if (!$arrCultures.contains($strCulture.tolower())) {$strCulture = (Get-Culture).name }

	[System.Reflection.Assembly]::Load("sysglobl, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a, processorArchitecture=MSIL") | Out-Null
	$GEOID = (New-Object System.Globalization.CultureAndRegionInfoBuilder($strCulture, "Replacement")).GEOID
	Return $GEOID
}

function RenameNetConn($strOldConnName, $strNewConnName)
{
	$InterfaceName = Get-WmiObject Win32_NetworkAdapter | where { $_.NetConnectionID -eq $strOldConnName }
	$interfaceName.netConnectionID = $strNewConnName
	$InterFaceName.put() | Out-Null
}

function SetIP ($strMACAddress, $strIP, $strSubnetMask, $strGateway)
{
	$colNetConfig = Get-WmiObject -query "Select * from Win32_NetworkAdapterConfiguration Where IPEnabled = 'True'"
	$colNetConfig | foreach-object {
		if ($_.MACAddress -match $strMACAddress)
		{
			$_.EnableStatic($strIP, $strSubnetMask) | Out-Null
			$_.SetGateways($strGateway) | Out-Null
		}
	}
}

function GetIP($strMACAddress)
{
	$colNetConfig = Get-WmiObject -query "Select * from Win32_NetworkAdapterConfiguration Where IPEnabled = 'True'"
	$colNetConfig | foreach-object {
		if ($_.MACAddress -match $strMACAddress)
		{
			$strIP = $_.IPAddress[0]
			return $strIP
		}
	}
}

function GetSubnetMask($strMACAddress)
{
	$colNetConfig = Get-WmiObject -query "Select * from Win32_NetworkAdapterConfiguration Where IPEnabled = 'True'"
	$colNetConfig | foreach-object {
	if ($_.MACAddress -match $strMACAddress)
	{
		$strNetMask = $_.IPSubnet[0]
			return $strNetMask
	}
}
}

function ValidateSubnetMask ($strSubnetMask)
{
	$bValidMask = $true
	$arrSections = @()
	$arrSections +=$strSubnetMask.split(".")
	#firstly, make sure there are 4 sections in the subnet mask
	if ($arrSections.count -ne 4) {$bValidMask =$false}
	
	#secondly, make sure it only contains numbers and it's between 0-255
	if ($bValidMask)
	{
		[reflection.assembly]::LoadWithPartialName("'Microsoft.VisualBasic") | Out-Null
		foreach ($item in $arrSections)
		{
			if (!([Microsoft.VisualBasic.Information]::isnumeric($item))) {$bValidMask = $false}
		}
	}
	
	if ($bValidMask)
	{
		foreach ($item in $arrSections)
		{
			$item = [int]$item
			if ($item -lt 0 -or $item -gt 255) {$bValidMask = $false}
		}
	}
	
	#lastly, make sure it is actually a subnet mask when converted into binary format
	if ($bValidMask)
	{
		foreach ($item in $arrSections)
		{
			$binary = [Convert]::ToString($item,2)
			if ($binary.length -lt 8)
			{
				do {
				$binary = "0$binary"
				} while ($binary.length -lt 8)
			}
			$strFullBinary = $strFullBinary+$binary
		}
		if ($strFullBinary.contains("01")) {$bValidMask = $false}
		if ($bValidMask)
		{
			$strFullBinary = $strFullBinary.replace("10", "1.0")
			if ((($strFullBinary.split(".")).count -ne 2)) {$bValidMask = $false}
		}
	}
	Return $bValidMask
}

function ValidateIP ($strIP)
{
	$bValidIP = $true
	$arrSections = @()
	$arrSections +=$strIP.split(".")
	#firstly, make sure there are 4 sections in the IP address
	if ($arrSections.count -ne 4) {$bValidIP =$false}
	
	#secondly, make sure it only contains numbers and it's between 0-254
	if ($bValidIP)
	{
		[reflection.assembly]::LoadWithPartialName("'Microsoft.VisualBasic") | Out-Null
		foreach ($item in $arrSections)
		{
			if (!([Microsoft.VisualBasic.Information]::isnumeric($item))) {$bValidIP = $false}
		}
	}
	
	if ($bValidIP)
	{
		foreach ($item in $arrSections)
		{
			$item = [int]$item
			if ($item -lt 0 -or $item -gt 254) {$bValidIP = $false}
		}
	}
	
	Return $bValidIP
}

function GetNetwork($strIPAddress, $strSubnetMask)
{
	$strNetwork = ""
	$arrIP = $strIPAddress.split(".")
	$arrNetMask = $strSubnetMask.split(".")
					
	for ($i = 0; $i -le 3; $i++)
	{
		if ($strNetwork -ne "")
		{
			$strNetwork = $strNetwork + "."
		}
														
		if ($arrNetMask[$i] -eq 255)
		{
			$strNetwork = $strNetwork + $arrIP[$i]
		}
		else
		{
			$strNetwork = $strNetwork + $arrNetMask[$i]
		}
	}
	return $strNetwork
}

function UserInput($strMsg, $intStyle)
{
	#$strMsg: Message displayed on the console sreen
	#$intStyle: User Input Style:
		#1 = Read-Host (Multiple characters, require to press Enter);
		#2 = $host.ui.rawui.readkey() (Single character, do not require to press enter)
	switch($intStyle)
	{
		1 { $host.ui.rawui.foregroundcolor = $Global:UserInputColor ; $strInput = Read-Host $strMsg ; $host.ui.rawui.foregroundcolor = $Global:fgColor ; return $strInput }
		2 { Write-Host $strMsg -foreground $Global:UserInputColor; $strInput = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown"); return $strInput}
	}
}


function GetKMSSetupKey($sku, $OSMajorVersion)
{
	$KMSSetupKey = $null
	Switch ($OSMajorVersion)
	{
	#Windows Vista and Windows Server 2008 Keys
	"6.0" 	{	switch($sku)
				{
					# Windows Vista Keys
					4	{ $KMSSetupKey = "VKK3X-68KWM-X2YGT-QR4M6-4BWMV" } #Enterprise Edition
					6	{ $KMSSetupKey = "YFKBB-PQJJV-G996G-VWGXY-2V3X8" } #Business Edition
					27	{ $KMSSetupKey = "VTC42-BM838-43QHV-84HX6-XJXKV" } #Enterprise N Edition
					16	{ $KMSSetupKey = "HMBQG-8H2RH-C77VX-27R82-VMQBT" } #Business N Edition
					
					# Windows Server 2008 keys
					8	{ $KMSSetupKey = "7M67G-PC374-GR742-YH8V4-TCBY3" } #Datacenter Server
					12	{ $KMSSetupKey = "22XQ2-VRXRG-P8D42-K34TD-G3QQC" } #Datacenter Server Core
					15	{ $KMSSetupKey = "4DWFP-JF3DJ-B7DTH-78FJB-PDRHK" } #Enterprise Server for Itanium based
					10	{ $KMSSetupKey = "YQGMW-MPWTJ-34KDK-48M3W-X4Q6V" } #Enterprise Server
					14	{ $KMSSetupKey = "39BXF-X8Q23-P2WWT-38T2F-G3FPG" } #Enterprise Server Core
					7	{ $KMSSetupKey = "TM24T-X9RMF-VWXK6-X8JC9-BFGM2" } #Standard Server
					13	{ $KMSSetupKey = "W7VD6-7JFBR-RX26B-YKQ3Y-6FFFJ" } #Standard Server Core
					17	{ $KMSSetupKey = "WYR28-R7TFJ-3X2YQ-YCY4H-M249D" } #Web Server
					default { $KMSSetupKey = $null }
				}
			}
	#In Windows Server 2008 R2, Server Core and standard install share the same KMS Client Setup Key		
	"6.1" 	{	switch($sku)
				{
					# Windows 7 keys
					48	{ $KMSSetupKey = "FJ82H-XT6CR-J8D7P-XQJJ2-GPDD4" } #Professional Edition
					49	{ $KMSSetupKey = "MRPKT-YTG23-K7D7T-X2JMM-QY7MG" } #Professional N Edition
					4	{ $KMSSetupKey = "33PXH-7Y6KF-2VJC9-XBBR8-HVTHH" } #Enterprise Edition
					27	{ $KMSSetupKey = "YDRBP-3D83W-TY26F-D46B2-XCKRJ" } #Enterprise N Edition
					70	{ $KMSSetupKey = "C29WB-22CC8-VJ326-GHFJW-H9DH4" } #Enterprise E Edition
					
					# Windows Server 2008 R2 keys
					8	{ $KMSSetupKey = "74YFP-3QFB3-KQT8W-PMXWJ-7M648" } #Datacenter Server
					18	{ $KMSSetupKey = "FKJQ8-TMCVP-FRMR7-4WR42-3JCD7" } #HPC Edition
					12	{ $KMSSetupKey = "74YFP-3QFB3-KQT8W-PMXWJ-7M648" } #Datacenter Server Core
					15	{ $KMSSetupKey = "GT63C-RJFQ3-4GMB6-BRFB9-CB83V" } #Enterprise Server for Itanium based
					10	{ $KMSSetupKey = "489J6-VHDMP-X63PK-3K798-CPX3Y" } #Enterprise Server
					14	{ $KMSSetupKey = "489J6-VHDMP-X63PK-3K798-CPX3Y" } #Enterprise Server Core
					7	{ $KMSSetupKey = "YC6KT-GKW9T-YTKYR-T4X34-R7VHC" } #Standard Server
					13	{ $KMSSetupKey = "YC6KT-GKW9T-YTKYR-T4X34-R7VHC" } #Standard Server Core
					17	{ $KMSSetupKey = "6TPJF-RBVHG-WBW2R-86QPH-6RTM4" } #Web Server
					default { $KMSSetupKey = $null }
				}
			}
	}
	return $KMSSetupKey
}

