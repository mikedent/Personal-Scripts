<#

.SYNOPSIS
	This script quick launches the UCS GUI from a saved credentials file.

.DESCRIPTION
	This script quick launches the UCS GUI from a saved credentials file.

.EXAMPLE
	Start-UcsGui.ps1
	This script can be run without any command line parameters.  User will be prompted for all parameters and options required

.EXAMPLE
	Start-UcsGui.ps1 -ucs "1.2.3.4" -savedcred "myucscred.csv"
	-ucs -- UCS Manager IP address or Host Name -- Example: "1.2.3.4" or "myucs" or "myucs.domain.local"
	-savedcred -- UCS Manager Credential File -- Add this option to locate a credentials file that is not located in the same folder as this script or named differently than myucscred.csv
		To create a credentials file: $credential = Get-Credential ; $credential | select username,@{Name="EncryptedPassword";Expression={ConvertFrom-SecureString $_.password}} |Export-CSV -NoTypeInformation .\myucscred.csv
		Make sure the password file is located in the same folder as the script
	All parameters are optional and any skipped will be prompted for during execution
	The only prompts that will always be presented would be for error recovery

.EXAMPLE
	Start-UcsGui.ps1 -ucs "1.2.3.4" -savedcred "myucscred.csv" -nossl
	-ucs -- UCS Manager IP address or Host Name -- Example: "1.2.3.4" or "myucs" or "myucs.domain.local"
	-savedcred -- UCS Manager Credential File -- Add this option to locate a credentials file that is not located in the same folder as this script or named differently than myucscred.csv
		To create a credentials file: $credential = Get-Credential ; $credential | select username,@{Name="EncryptedPassword";Expression={ConvertFrom-SecureString $_.password}} |Export-CSV -NoTypeInformation .\myucscred.csv
		Make sure the password file is located in the same folder as the script
	-nossl -- Launches UCSM GUI using HTTP instead of HTTPS
	All parameters are optional and any skipped will be prompted for during execution
	The only prompts that will always be presented would be for error recovery
.NOTES
	Author: Joe Martin
	Email: joemar@cisco.com
	Company: Cisco Systems, Inc.
	Version: v0.1.02
	Date: 6/19/2014
	Disclaimer: Code provided as-is.  No warranty implied or included.  This code is for example use only and not for production

.INPUTS
	UCSM IP Address or Hostname
	UCSM Credentials Filename

.OUTPUTS
	Launching of UCSM GUI
	
.LINK
	http://communities.cisco.com/people/joemar/content

#>

#Command Line Parameters
param(
	[string]$UCSM,				# IP Address or Hostname.
	[string]$SAVEDCRED,			# Saved UCSM Credentials.  To create do: $credential = Get-Credential ; $credential | select username,@{Name="EncryptedPassword";Expression={ConvertFrom-SecureString $_.password}} | Export-CSV -NoTypeInformation .\myucscred.csv
	[switch]$NOSSL				# Launches UCSM GUI without HTTPS/SSL
)

#Set script error handling
#$ErrorActionPreference = "SilentlyContinue"
$ErrorActionPreference = "Stop"
#$ErrorActionPreference = "Continue"
#$ErrorActionPreference = "Inquire"

#Clear the screen
clear-host

#Script kicking off
Write-Output "Script Running..."
Write-Output ""

#Tell the user what the script does
Write-Output "This script will launch the UCSM GUI rapidly by"
Write-Output "allowing the user to only specify the UCSM address"
Write-Output "and use a saved credentials file"
Write-Output ""
Write-Output "To create a saved credentials file do the following:"
Write-Output '	$credential = Get-Credential'
Write-Output '	$credential | select username,@{Name="EncryptedPassword";Expression={ConvertFrom-SecureString $_.password}} | Export-CSV -NoTypeInformation .\myucscred.csv'
Write-Output ""

#Change directory to the script root
cd $PSScriptRoot

if (!$SAVEDCRED)
	{
		$SAVEDCRED = '.\myucscred.csv'
	}

#Select folder to save files to
$TestPath = Test-Path $SAVEDCRED
if ($TestPath -eq $true)
	{
		#Hold for future options
	}
else
	{
		Write-Output "The file you specified either does not exist or you do not have access to it"
		Write-Output "	Exiting..."
		Disconnect-Ucs
		exit				
	}

#Load the UCS PowerTool
Write-Output "Checking Cisco PowerTool"
$PowerToolLoaded = $null
$Modules = Get-Module
$PowerToolLoaded = $modules.name
if ( -not ($Modules -like "ciscoUcsPs"))
	{
		Write-Output "	Loading Module: Cisco UCS PowerTool Module"
		Import-Module ciscoUcsPs
		$Modules = Get-Module
		if ( -not ($Modules -like "ciscoUcsPs"))
			{
				Write-Output ""
				Write-Output "	Cisco UCS PowerTool Module did not load.  Please correct his issue and try again"
				Write-Output "		Exiting..."
				exit
			}
		else
			{
				$PTVersion = (Get-Module CiscoUcsPs).Version
				Write-Output "		PowerTool version $PTVersion is now Loaded"
			}
	}
else
	{
		$PTVersion = (Get-Module CiscoUcsPs).Version
		Write-Output "	PowerTool version $PTVersion is already Loaded"
	}

#Load the saved crentials file and assign username and password
$CredFile = import-csv $SAVEDCRED -ErrorAction Stop
$Username = $CredFile.UserName
$Password = $CredFile.EncryptedPassword
$Cred = New-Object System.Management.Automation.PsCredential $Username,(ConvertTo-SecureString $Password)

#Select UCS Domain(s) for login
if ($UCSM -ne "")
	{
		$myucs = $UCSM
	}
else
	{
		$myucs = Read-Host "Enter UCS system IP or Hostname"
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
Write-Output ""
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

#This function launches the UCSM GUI
Function LaunchUCSM ($MyUcs, $Cred)
	{
		if ($NOSSL)
			{
				$myConPS = Connect-Ucs -Name  $MyUcs -Credential $Cred -NoSsl
			}
		else
			{
				$myConPS = Connect-Ucs -Name  $MyUcs -Credential $Cred
			}
		if ($myConPS.Name -ne $MyUcs)
			{
				Write-Output ""
				Write-Output "Failed to Connect"
				$script:Retry = Read-Host "Retry (Y/N)"
				if ($script:Retry -ieq "y")
					{
						$script:Success = "n"
						$script:Retry = "y"
					}
				else
					{
						Write-Output ""
						Write-Output "Exiting..."
						$script:Success = "n"
						$script:Retry = "n"
					}
			}
		else
			{
				$Name = $myConPS.Name
				$UCS = $myConPS.Ucs
				Write-Output ""
				Write-Output "You are connected to UCSM: $Name($UCS)"
				Write-Output "	Launching UCSM GUI"
				$myConGUI = Start-ucsguisession -LogAllXml -ErrorAction Stop
				$script:Success = "y"
				$script:Retry = "n"
			}	
	}

#Script Main
$script:Success = "n"
$script:Retry = "y"
do
	{
		LaunchUCSM $MyUcs $Cred
	}
while (($script:retry -eq "y") -and ($script:success -eq "n"))

#Disconnect from UCSM
Disconnect-Ucs

#Exit the Script
Write-Output ""
Write-Output "Script Complete"
exit