<#

.SYNOPSIS
	This script will go through each of your blades and rack servers and provide a user label with a basic inventory description.

.DESCRIPTION
	This script will go through each of your blades and rack servers and provide a user label with a basic inventory description. Ex. - B200-M3 / 2 x E5-2660 / 256GB

.EXAMPLE
	Set-UcsServerInventoryLabels.ps1
	This script can be run without any command line parameters.  User will be prompted for all parameters and options required

.EXAMPLE
	Set-UcsServerInventoryLabels.ps1 -ucs "1.2.3.4" -ucred
	-ucs -- UCS Manager IP or Host Name -- Example: "1.2.3.4" or "myucs" or "myucs.domain.local" or "1.2.3.4,5.6.7.8" or "myucs1,myucs2" or "myucs1.domain.local,myucs2.domain.local"
	-ucred -- UCS Manager Credential Switch -- Adding this switch will immediately prompt you for your UCSM username and password
	All parameters are optional and any skipped will be prompted for during execution
	The only prompts that will always be presented to the user will be for User Names and Passwords
	
.EXAMPLE
	Set-UcsServerInventoryLabels.ps1 -ucs "1.2.3.4" -saved "myucscred.csv" -skiperrors
	-ucs -- UCS Manager IP or Host Name -- Example: "1.2.3.4" or "myucs" or "myucs.domain.local" or "1.2.3.4,5.6.7.8" or "myucs1,myucs2" or "myucs1.domain.local,myucs2.domain.local"
	-savedcred -- UCSM credentials file -- Example: -savedcred "myucscred.csv"
		To create a credentials file: $credential = Get-Credential ; $credential | select username,@{Name="EncryptedPassword";Expression={ConvertFrom-SecureString $_.password}} |Export-CSV -NoTypeInformation .\myucscred.csv
		Make sure the password file is located in the same folder as the script
	-skiperrors -- Tells the script to skip any prompts for errors and continues with 'y'
	All parameters are optional and any skipped will be prompted for during execution
	The only prompts that will always be presented to the user will be for User Names and Passwords

.NOTES
	Author: Joe Martin
	Email: joemar@cisco.com
	Company: Cisco Systems, Inc.
	Version: v0.2.03
	Date: 7/21/2014
	Disclaimer: Code provided as-is.  No warranty implied or included.  This code is for example use only and not for production

.INPUTS
	UCSM IP Address(s) or Hostname(s)
	UCSM Username and Password
	UCSM Credentials File

.OUTPUTS
	None
	
.LINK
	http://communities.cisco.com/people/joemar/content

#>

#Command Line Parameters
param(
	[string]$UCSM,				# IP Address(s) or Hostname(s).  If multiple entries, separate by commas
	[switch]$UCREDENTIALS,		# UCSM Credentials (Username and Password)
	[string]$SAVEDCRED,			# Saved UCSM Credentials.  To create do: $credential = Get-Credential ; $credential | select username,@{Name="EncryptedPassword";Expression={ConvertFrom-SecureString $_.password}} | Export-CSV -NoTypeInformation .\myucscred.csv
	[switch]$SKIPERROR			# Skip any prompts for errors and continues with 'y'
)

#Clear the screen
clear-host

#Script kicking off
Write-Output "Script Running..."
Write-Output ""

#Gather any credentials requested from command line
if ($UCREDENTIALS)
	{
		$cred = Get-Credential -Message "Enter UCSM Credentials"
	}

#Change directory to the script root
cd $PSScriptRoot

#Check to see if credential files exists
if ($SAVEDCRED)
	{
		if ((Test-Path $SAVEDCRED) -eq $false)
			{
				Write-Output ""
				Write-Output "Your credentials file $SAVEDCRED does not exist in the script directory"
				Write-Output "	Exiting..."
				Disconnect-Ucs
				exit
			}
	}

#Do not show errors in script
$ErrorActionPreference = "SilentlyContinue"
#$ErrorActionPreference = "Stop"
#$ErrorActionPreference = "Continue"
#$ErrorActionPreference = "Inquire"

#Verify PowerShell Version for script support
$PSVersion = $psversiontable.psversion
$PSMinimum = $PSVersion.Major
if ($PSMinimum -ge "3")
	{
	}
else
	{
		Write-Output "This script requires PowerShell version 3 or above"
		Write-Output "Please update your system and try again."
		Write-Output "You can download PowerShell updates here:"
		Write-Output "	http://search.microsoft.com/en-us/DownloadResults.aspx?rf=sp&q=powershell+4.0+download"
		Write-Output "If you are running a version of Windows before 7 or Server 2008R2 you need to update to be supported"
		Write-Output "		Exiting..."
		Disconnect-Ucs
		exit
	}

#Tell the user what the script does
Write-Output "This script will go through each of your blades and rack servers and provide a"
Write-Output "user label with a basic inventory description."
Write-Output "	Example:"
Write-Output "		B200-M3 / 2 x E5-2660 / 256GB"
Write-Output ""

#Load the UCS PowerTool
Write-Output "Checking Cisco PowerTool"
$PowerToolLoaded = $null
$Modules = Get-Module
$PowerToolLoaded = $modules.name
if ( -not ($Modules -like "ciscoUcsPs"))
	{
		Write-Output "	Loading Module: Cisco UCS PowerTool Module"
		Import-Module Cisc.UCSManager
		$Modules = Get-Module
		if ( -not ($Modules -like "Cisco.UCSManager"))
			{
				Write-Output ""
				Write-Output "	Cisco UCS PowerTool Module did not load.  Please correct his issue and try again"
				Write-Output "		Exiting..."
				exit
			}
		else
			{
				Write-Output "		PowerTool is now Loaded"
			}
	}
else
	{
		Write-Output "	PowerTool is already Loaded"
	}

#Select UCS Domain(s) for login
if ($UCSM -ne "")
	{
		$myucs = $UCSM
	}
else
	{
		Write-Output ""
		$myucs = Read-Host "Enter UCS system IP or Hostname or a list of systems separated by commas"
	}
[array]$myucs = ($myucs.split(",")).trim()
if ($myucs.count -eq 0)
	{
		Write-Output ""
		Write-Output "You didn't enter anything"
		Write-Output "	Exiting..."
		Disconnect-Ucs
		exit
	}

#Make sure we are disconnected from all UCS Systems
Disconnect-Ucs

#Test that UCSM(s) are IP Reachable via Ping
Write-Output "Testing PING access to UCSM"
foreach ($ucs in $myucs)
	{
		$ping = new-object system.net.networkinformation.ping
		$results = $ping.send($ucs)
		if ($results.Status -ne "Success")
			{
				Write-Output "	Can not access UCSM $ucs by Ping"
				Write-Output "		It is possible that a firewall is blocking ICMP (PING) Access.  Would you like to try to log in anyway?"
				if ($SKIPERROR)
					{
						$Try = "y"
					}
				else
					{
						$Try = Read-Host "Would you like to try to log in anyway? (Y/N)"
					}		
				if ($Try -ieq "y")
					{
						Write-Output "				Will try to log in anyway!"
					}
				elseif ($Try -ieq "n")
					{
						Write-Output ""
						Write-Output "You have chosen to exit"
						Write-Output "	Exiting..."
						Disconnect-Ucs
						exit
					}
				else
					{
						Write-Output ""
						Write-Output "You have provided invalid input"
						Write-Output "	Exiting..."
						Write-Output ""
						Disconnect-Ucs
						exit
					}			
			}
		else
			{
				Write-Output "	Successful access to $ucs by Ping"
			}
	}

#Log into the UCS System(s)
$multilogin = Set-UcsPowerToolConfiguration -SupportMultipleDefaultUcs $true
Write-Output ""
Write-Output "Logging into UCS"

#Verify PowerShell Version to pick prompt type
$PSVersion = $psversiontable.psversion
$PSMinimum = $PSVersion.Major
if (!$UCREDENTIALS)
	{
		if (!$SAVEDCRED)
			{
				if ($PSMinimum -ge "3")
					{
						Write-Output "	Enter your UCSM credentials"
						$cred = Get-Credential -Message "UCSM(s) Login Credentials" -UserName "admin"
					}
				else
					{
						Write-Output "	Enter your UCSM credentials"
						$cred = Get-Credential
					}
			}
		else
			{
				$CredFile = import-csv $SAVEDCRED
				$Username = $credfile.UserName
				$Password = $credfile.EncryptedPassword
				$cred = New-Object System.Management.Automation.PsCredential $Username,(ConvertTo-SecureString $Password)			
			}
	}
foreach ($myucslist in $myucs)
	{
		Write-Output "		Logging into: $myucslist"
		$myCon = $null
		$myCon = Connect-Ucs $myucslist -Credential $cred
		if (($mycon).Name -ne ($myucslist)) 
			{
				#Exit Script
				Write-Output "			Error Logging into this UCS domain"
				if ($myucs.count -le 1)
					{
						$continue = "n"
					}
				else
					{
						if ($SKIPERROR)
							{
								$continue = "y"
							}
						else
							{
								$continue = Read-Host "Continue without this UCS domain (Y/N)"
							}
					}
				if ($continue -ieq "n")
					{
						Write-Output ""
						Write-Output "Exiting Script..."
						Disconnect-Ucs
						exit
					}
				else
					{
						Write-Output "				Continuing..."
					}
			}
		else
			{
				Write-Output "			Login Successful"
			}
		sleep 1
	}
if ($myCon.count -eq 0)
	{
		Write-Output ""
		Write-Output "You are not logged into any UCSM systems"
		Write-Output "	Exiting..."
		Disconnect-Ucs
		exit
	}

#Generating Labels for Blade Servers
if ((Get-UcsBlade).Count -ne 0)
	{
		Write-Output ""
		Write-Output "Generating User Labels for Blade Servers..."
		foreach ($Blade in (Get-UcsBlade | Sort-Object -Property Ucs, ChassisId, SlotId))
			{
				$Model = (($Blade | Get-UcsCapability).Name -replace "Cisco UCS ", "") -replace " ", "-"
				$Long = $Blade | Get-UcsComputeBoard | Get-UcsProcessorUnit -Id 1 | select -ExpandProperty Model
				if ($Long -match 'Intel.*?([EXL\-57]+\s*\d{4}L*\b(\sv2)?)')
					{
						$CPU = $Matches[1] -replace '- ', "-"
					}
				else
					{
						$CPU = "<<<Unknown>>>"
					}
				$RAM = ($Blade.TotalMemory / 1KB)
				$NumberOfCPUs = $Blade.NumOfCpus
				$CustomLabel = "$Model / $NumberOfCPUs x $CPU / $RAM"+"GB"
				$Blade | Set-UcsBlade -UsrLbl $CustomLabel -Force | Out-Null
				$Display = "	UCS: "+($Blade.Ucs).PadRight(32)+"	Chassis: "+$Blade.ChassisId+"	Slot: "+$Blade.SlotId+"	User Label: "+$CustomLabel
				Write-Output $Display
			}
	}

#Generating Labels for Rack Servers
if ((Get-UcsRackUnit).Count -ne 0)
	{
		Write-Output ""
		Write-Output "Generating User Labels for Rack Servers..."
		foreach ($Rack in (Get-UcsRackUnit | Sort-Object -Property Ucs, ServerId)) 
			{
				$Model = (($Rack | Get-UcsCapability).Name -replace "Cisco UCS ", "") -replace " ", "-"
				$Long = $Rack | Get-UcsComputeBoard | Get-UcsProcessorUnit -Id 1 | select -ExpandProperty Model
				if ($Long -match 'Intel.*?([EXL\-57]+\s*\d{4}L*\b(\sv2)?)')
					{
						$CPU = $Matches[1] -replace '- ', "-"
					}
				else
					{
						$CPU = "<<<Unknown>>>"
					}
				$RAM = ($Rack.TotalMemory / 1KB)
				$NumberOfCPUs = $Rack.NumOfCpus
				$CustomLabel = "$Model / $NumberOfCPUs x $CPU / $RAM"+"GB"
				$Rack | Set-UcsRackUnit -UsrLbl $CustomLabel -Force | Out-Null
				$Display = "	UCS: "+($Rack.Ucs).PadRight(32)+"	Rack Unit: "+$Rack.ServerId+"		User Label: "+$CustomLabel
				Write-Output $Display
			}
	}

#There are no blade or rack servers
if (((Get-UcsBlade).Count -eq 0) -and ((Get-UcsRackUnit).Count -eq 0))
	{
		Write-Output ""
		Write-Output "Your UCS System(s) do not contain any blade or rack servers"
		Write-Output "	Exiting..."
	}

#Disconnect from UCSM(s)
Disconnect-Ucs

#Exit the Script
Write-Output ""
Write-Output "Script Complete"
Write-Output "     Exiting..."
exit