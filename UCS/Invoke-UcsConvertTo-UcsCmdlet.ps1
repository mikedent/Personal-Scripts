<#

.SYNOPSIS
	This script will launch UCSM GUI and execute the ConvertTo-UcsCmdlet.  That cmdlet allows you to learn UCS PowerTool very easily.

.DESCRIPTION
	This script will launch UCSM GUI and execute the ConvertTo-UcsCmdlet.  That cmdlet allows you to learn UCS PowerTool very easily.

.EXAMPLE
	Invoke-UcsConvertTo-UcsCmdlet.ps1
	This script can be run without any command line parameters.  User will be prompted for all parameters and options required

.EXAMPLE
	Invoke-UcsConvertTo-UcsCmdlet.ps1 -ucs "1.2.3.4" -ucred
	-ucs -- UCS Manager IP or Host Name -- Example: "1.2.3.4" or "myucs" or "myucs.domain.local"
	-ucred -- UCS Manager Credential Switch -- Adding this switch will immediately prompt you for your UCSM username and password
	All parameters are optional and any skipped will be prompted for during execution
	The only prompts that will always be presented to the user will be for User Names and Passwords
	
.EXAMPLE
	Invoke-UcsConvertTo-UcsCmdlet.ps1 -ucs "1.2.3.4" -saved "myucscred.csv" -skiperrors
	-ucs -- UCS Manager IP or Host Name -- Example: "1.2.3.4" or "myucs" or "myucs.domain.local"
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
	Version: v0.4.02
	Date: 7/11/2014
	Disclaimer: Code provided as-is.  No warranty implied or included.  This code is for example use only and not for production

.INPUTS
	UCSM IP Address(s) or Hostname(s)
	UCSM Username and Password
	UCSM Credentials Filename

.OUTPUTS
	Look in your PowerShell windows for the output from ConvertTo-UcsCmdlet
	
.LINK
	http://communities.cisco.com/people/joemar/content

#>

#Command Line Parameters
param(
	[string]$UCSM,				# IP Address or Hostname
	[switch]$UCREDENTIALS,		# UCSM Credentials
	[string]$SAVEDCRED,			# Saved UCSM Credentials.  To create do: $credential = Get-Credential ; $credential | select username,@{Name="EncryptedPassword";Expression={ConvertFrom-SecureString $_.password}} | Export-CSV -NoTypeInformation .\myucscred.csv
	[switch]$SKIPERROR			# Skip any prompts for errors and continues with 'y'
)

#Clear the screen
clear-host

#Script kicking off
Write-Output "Script Running..."
Write-Output ""

#Tell the user what the script does
Write-Output "This script will launch UCSM GUI and execute the ConvertTo-UcsCmdlet"
Write-Output ""
Write-Output "The value of this function is to learn the PowerShell required to perform"
Write-Output "a task"
Write-Output ""
Write-Output "Just do something in UCSM, select SAVE and look at your PowerShell console"
Write-Output "to see the PowerShell commands"

#Gather any credentials requested from command line
if ($UCREDENTIALS)
	{
		Write-Output ""
		Write-Output "Enter UCSM Credentials"
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

#Load the UCS PowerTool
Write-Output ""
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
				Write-Output "	PowerTool is Loaded"
			}
	}
else
	{
		Write-Output "	PowerTool is Loaded"
	}

#Define UCS Domain(s)
Write-Output ""
Write-Output "Validating Connectivity to UCSM"
Write-Output "	Enter UCS system IP or Hostname"
if ($UCSM -ne "")
	{
		$myucs = $UCSM
	}
else
	{
		$myucs = Read-Host "Enter UCS system IP or Hostname"
	}
if (($myucs -eq "") -or ($myucs -eq $null) -or ($Error[0] -match "PromptingException"))
	{
		Write-Output ""
		Write-Output "You have provided invalid input."
		Write-Output "	Exiting..."
		Disconnect-Ucs
		exit
	}
else
	{
		Disconnect-Ucs
	}

#Test that UCSM is IP Reachable via Ping
Write-Output ""
Write-Output "Testing reachability to UCSM"
$ping = new-object system.net.networkinformation.ping
$results = $ping.send($myucs)
if ($results.Status -ne "Success")
	{
		Write-Output "	Can not access UCSM $myucs by Ping"
		Write-Output ""
		Write-Output "It is possible that a firewall is blocking ICMP (PING) Access.  Would you like to try to log in anyway?"
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
				Write-Output ""
				Write-Output "Trying to log in anyway!"
				Write-Output ""
			}
		elseif ($Try -ieq "n")
			{
				Write-Output ""
				Write-Output "You have chosen to exit"
				Write-Output"	Exiting..."
				Disconnect-Ucs
				exit
			}
		else
			{
				Write-Output ""
				Write-Output "You have provided invalid input.  Please enter (Y/N) only."
				Write-Output "	Exiting..."
				Disconnect-Ucs
				exit
			}			
	}
else
	{
		Write-Output "	Successfully pinged UCSM: $myucs"
	}
	
#Allow Logins to single or multiple UCSM systems
$multilogin = Set-UcsPowerToolConfiguration -SupportMultipleDefaultUcs $false

#Log into UCSM
Write-Output ""
Write-Output "Logging into UCSM"
Write-Output "	Provide UCSM login credentials"

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
$myCon = Connect-Ucs $myucs -Credential $cred
if (($myucs | Measure-Object).count -ne ($myCon | Measure-Object).count) 
	{
	#Exit Script
	Write-Output "		Error Logging into UCS.  Make sure your user has login rights the UCS system and has the proper role/privledges to use this tool..."
	Write-Output "			Exiting..."
	Disconnect-Ucs
	exit
	}
else
	{
		if (!$UCREDENTIALS)
			{
				Write-Output "		Login Successful"
			}
		else
			{
				Write-Output "	Login Successful"
			}
	}
$myCon = Start-ucsguisession -LogAllXml

##Launch UCSM GUI
Write-Output ""
Write-Output "Launching UCSM GUI"

#Wait till Java Log file is ready
function Start-Countdown
	{
		Param
			(
				[INT]$Seconds = (Read-Host "Enter seconds to countdown from")
			)
		while
			(
				$seconds -ge 0
			)
			{
    				Write-Progress -Activity "Sleep Timer Countdown" -SecondsRemaining $Seconds -Status "Time Remaining"
    				Start-Sleep -Seconds 1
				$Seconds --
			}
		Write-Progress -Completed -Activity "Sleep Timer Countdown"
	}
Write-Output ""
Write-Output "Waiting for 1 minute to make sure the UCSM log file is ready for use."
Write-Output "	Do NOT make any changes using the UCSM GUI until the timer has expired and the ConvertTo-UcsCmdlet function is executing."
Start-Countdown -seconds 60

##Execute the ConvertTo-UcsCmdlet option
Write-Output ""
Write-Output 'Executing ConvertTo-UcsCmdlet'
Write-Output "	Make sure to end script when done as the ConvertTo-UcsCmdlet will run forever still stopped"
Write-Output ""
ConvertTo-UcsCmdlet