<#

.SYNOPSIS
	This script configures LDAP integration to Microsoft Active Directory.

.DESCRIPTION
	This script configures LDAP integration to Microsoft Active Directory.
	Fill out the global variables section before running

.EXAMPLE
	New-UcsAdIntegration.ps1
	This script can be run without any command line parameters.  User will be prompted for all parameters and options required

.EXAMPLE
	New-UcsAdIntegration.ps1 -ucs "1.2.3.4" -ucred
	-ucs -- UCS Manager IP address(s) or Host Name(s) -- Example: "1.2.3.4" or "myucs" or "myucs.domain.net" or "1.2.3.4,5.6.7.8" or "myucs1,myucs2" or "myucs1.domain.net,myucs2.domain.net"
	-ucred -- UCS Manager Credential Switch -- Adding this switch will immediately prompt you for your UCSM username and password
	All parameters are optional and any skipped will be prompted for during execution
	The only prompts that will always be presented to the user will be for User Names and Passwords

.EXAMPLE
	New-UcsAdIntegration.ps1 -ucs "1.2.3.4" -saved "myucscred.csv" -skiperror
	-ucs -- UCS Manager IP address(s) or Host Name(s) -- Example: "1.2.3.4" or "myucs" or "myucs.domain.net" or "1.2.3.4,5.6.7.8" or "myucs1,myucs2" or "myucs1.domain.net,myucs2.domain.net"
	-savedcred -- UCSM credentials file -- Example: -savedcred "myucscred.csv"
		To create a credentials file: $credential = Get-Credential ; $credential | select username,@{Name="EncryptedPassword";Expression={ConvertFrom-SecureString $_.password}} |Export-CSV -NoTypeInformation .\myucscred.csv
		Make sure the password file is located in the same folder as the script
	-skiperrors -- Tells the script to skip any prompts for errors and continues with 'y'
	All parameters are optional and any skipped will be prompted for during execution
	The only prompts that will always be presented to the user will be for User Names and Passwords

.NOTES
	Author: Joe etherbacon
	Email: joemar@cisco.com
	Company: Cisco Systems, Inc.
	Version: v0.1.00
	Date: 5/9/2015
	Disclaimer: Code provided as-is.  No warranty implied or included.  This code is for example use only and not for production

.INPUTS
	UCSM IP Address(s) or Hostname(s)
	UCSM Credentials Filename
	UCSM Username and Password
	AD Service Account Password

.OUTPUTS
	None
	
.LINK
	http://communities.cisco.com/people/joemar/content

#>

#Command Line Parameters
param(
	[string]$UCSM,				# IP Address(s) or Hostname(s).  If multiple entries, separate by commas
	[switch]$UCREDENTIALS,		# UCSM Credentials (Username and Password).  Requires all domains to use the same credentials
	[string]$SAVEDCRED,			# Saved UCSM Credentials.  To create do: $credential = Get-Credential ; $credential | select username,@{Name="EncryptedPassword";Expression={ConvertFrom-SecureString $_.password}} | Export-CSV -NoTypeInformation .\myucscred.csv
	[switch]$SKIPERROR			# Skip any prompts for errors and continues with 'y'
)

#Global Variables: BEGIN--------------------------------------------------------------------------------------------------------------------------

Write-Output "Reading in global variables"

#If your UCS is not configured for DNS, enter the DNS info below:
##Example: $DnsDomain = 'etherbacon.net'
$DnsDomain = 'etherbacon.net'

##Example: $DnsServers = @('10.0.1.101', '10.0.1.102', '10.0.1.119')
$DnsServers = @('10.10.200.2', '10.10.201.2')


#If your UCS is not configured for NTP, enter the NTP info below:
##Example: $TimeZone = 'America/Los_Angeles (Pacific Time)'
$TimeZone = 'America/Los_Angeles (Pacific Time)'

##Example: $NtpServers = @('10.0.0.1', 'tick.usno.navy.mil', 'tock.usno.navy.mil')
$NtpServers = @('time.nist.gov')


#Global Variables for LDAP integration with Active Directory
##Example: $ProviderFQDN = 'etherbacon.net'
###Enter your top level domain
$ProviderFQDN = 'etherbacon.net'

##Example: $BindDn = 'CN=UCS Bind,OU=Service Accounts,DC=etherbacon,DC=net'
###Enter the AD service account that will be used to access AD to validate credentials
####NOTE: Enter the user account first and last name, not the account name
$BindDn = 'CN=DirectoryBind,OU=Users,OU=EtherbaconOU,DC=etherbacon,DC=net'

##Example: $BaseDn = 'DC=etherbacon,DC=net'
###This will be the top level domain info.  Recursion will be used to drill down into the domain
$BaseDn = 'DC=etherbacon,DC=net'

##Example: $Filter = 'sAMAccountName=$userid'
###Do not change this value
$Filter = 'sAMAccountName=$userid'

##Example: $GroupMaps = @{'admin' = 'CN=UCS_Admins,OU=Service Accounts,DC=etherbacon,DC=net' ; 'read-only' = 'CN=UCS_ReadOnly,OU=Service Accounts,DC=etherbacon,DC=net'}
###This is the mapping of UCS roles to the AD security groups
####You will assign these security groups to the various users in your org who need access to UCS with various roles
$GroupMaps = @{'admin' = 'CN=UCSAdmins,OU=Users,OU=EtherbaconOU,DC=etherbacon,DC=net'}

Write-Output "	Done"
Write-Output ""

#Global Variables: END----------------------------------------------------------------------------------------------------------------------------

#Clear the screen
clear-host

#Script kicking off
Write-Output "Script Running..."
Write-Output ""

#Tell the user what the script does
Write-Output "This script will configure Microsoft Active Directory integration to UCS."
Write-Output "This script requires the creation of a few items in AD:"
Write-Output "	Service Account in AD to be used for validating credentials"
Write-Output "		NOTE: Assign a first name and last name on this account"
Write-Output "		Recommendation: Assign a long lived password on the Service Account"
Write-Output "	Security Groups which match the user roles in UCS"
Write-Output "	Assign the Security Groups to the various users who need to access UCS"
Write-Output ""
Write-Output "This script also offers to configure DNS Name, DNS Servers, TimeZone and NTP Servers"
Write-Output "	These items are important to the AD integration"
Write-Output ""

if ($UCREDENTIALS)
	{
		Write-Output "Enter UCSM Credentials"
		Write-Output ""
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
Write-Output "Checking for proper PowerShell version"
$PSVersion = $psversiontable.psversion
$PSMinimum = $PSVersion.Major
if ($PSMinimum -ge "3")
	{
		Write-Output "	Your version of PowerShell is valid for this script."
		Write-Output "		You are running version $PSVersion"
		Write-Output ""
	}
else
	{
		Write-Output "	This script requires PowerShell version 3 or above"
		Write-Output "		You are running version $PSVersion"
		Write-Output "	Please update your system and try again."
		Write-Output "	You can download PowerShell updates here:"
		Write-Output "		http://search.microsoft.com/en-us/DownloadResults.aspx?rf=sp&q=powershell+4.0+download"
		Write-Output "	If you are running a version of Windows before 7 or Server 2008R2 you need to update to be supported"
		Write-Output "			Exiting..."
		Disconnect-Ucs
		exit
	}

#Load the UCS PowerTool
Write-Output "Checking Cisco PowerTool"
$PowerToolLoaded = $null
$Modules = Get-Module
$PowerToolLoaded = $modules.name
if ( -not ($Modules -like "Cisco.UCSManager"))
	{
		Write-Output "	Loading Module: Cisco UCS PowerTool Module"
		Import-Module Cisco.UCSManager
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
				$PTVersion = (Get-Module Cisco.UCSManager).Version
				Write-Output "		PowerTool version $PTVersion is now Loaded"
			}
	}
else
	{
		$PTVersion = (Get-Module Cisco.UCSManager).Version
		Write-Output "	PowerTool version $PTVersion is already Loaded"
	}

#Select UCS Domain(s) for login
if ($UCSM -ne "")
	{
		$myucs = $UCSM
	}
else
	{
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
					}				if ($Try -ieq "y")
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
						$continue = Read-Host "Continue without this UCS domain (Y/N)"
					}
				if ($continue -ieq "n")
					{
						Write-Output "				You have chosen to exit..."
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
$myCon = (Get-UcsPSSession | measure).Count
if ($myCon -eq 0)
	{
		Write-Output ""
		Write-Output "You are not logged into any UCSM systems"
		Write-Output "	Exiting..."
		Disconnect-Ucs
		exit
	}

Write-Output ""

##This will prompt you for the credentials of the AD service account
Write-Output "Gathering Service Account Password"
$ProviderCred = Read-Host -Prompt "Enter AD Service Account Password"
if (!$ProviderCred)
	{
		Write-Output "	You did not set a password for the AD Service Account"
		Write-Output ""
		Write-Output "If you continue you will need to add the password manually"
		$Answer = Read-Host "Do you want to continue (Y/N)"
		if ($Answer -ieq "Y")
			{
				$ProviderCred = ""
				Write-Output ""
				Write-Output "	Continuing"
			}
		else
			{
				Write-Output ""
				Write-Output "	Exiting"
				Disconnect-Ucs
				exit
			}
	}
else
	{
		Write-Output "	Done"
		Write-Output ""
	}

#Add Timezone to UCS if needed
Write-Output "Adding Timezone"
if ($TimeZone)
	{
		Get-UcsTimezone | Set-UcsTimezone -Force -adminState enabled -policyOwner net -port '0' -timezone $TimeZone
	}
Write-Output "	Done"
Write-Output ""

#Add NTP servers to UCS if needed
Write-Output "Adding NTP Server(s)"
if ($NtpServers)
	{
		foreach ($NtpServer in $NtpServers)
			{
				Add-UcsNtpServer -ModifyPresent -name $NtpServer
			}
	}
Write-Output "	Done"
Write-Output ""

#Add DNS domain to UCS if needed
Write-Output "Adding DNS Domain"
if ($DnsDomain)
	{
		Get-UcsDns | Set-UcsDns -Force -adminState enabled -domain $DnsDomain -policyOwner net -port '0'
	}
Write-Output "	Done"
Write-Output ""

#Add DNS Servers to UCS if needed
Write-Output "Adding DNS Server(s)"
if ($DnsServers)
	{
		foreach ($DnsServer in $DnsServers)
			{
				Add-UcsDnsServer -ModifyPresent -name $DnsServer
			}
	}
Write-Output "	Done"
Write-Output ""

#Create UCS LDAP Provider
Write-Output "Creating UCS LDAP Provider"
Add-UcsLdapProvider -Name $ProviderFQDN -Basedn $BaseDN -Filter $Filter -Rootdn $BindDn -Key $ProviderCred -Vendor "MS-AD"
$ProviderCred = $null
Add-UcsLdapGroupRule -LdapProvider $ProviderFQDN -TargetAttr 'MemberOf' -Traversal recursive -Authorization enable
Write-Output "	Done"
Write-Output ""

#Create UCS LDAP Provider Group
Write-Output "Creating UCS LDAP Provider Group"
$LdapGlobal = Get-UcsLdapGlobalConfig
Add-UcsProviderGroup -Name $ProviderFQDN -LdapGlobalConfig $LdapGlobal
$ProviderGroup = Get-UcsProviderGroup
Add-UcsProviderReference -ProviderGroup $ProviderGroup -Name $ProviderFQDN
Write-Output "	Done"
Write-Output ""

#Create UCS LDAP Group Maps
Write-Output "Creating UCS LDAP Provider Group Maps"
foreach ($GroupMap in $GroupMaps.Keys)
	{
		Add-UcsLdapGroupMap -Name $GroupMaps.$GroupMap
		Add-UcsUserRole -LdapGroupMap $GroupMaps.$GroupMap -Name $GroupMap
		Add-UcsUserRole -LdapGroupMap $GroupMaps.$GroupMap -Name "read-only"
	}
Write-Output "	Done"
Write-Output ""

#Create Authentication Domains
Write-Output "Create UCS Authentication Domains"
Add-UcsAuthDomain -Name $ProviderFQDN
Set-UcsAuthDomainDefaultAuth -Realm ldap -AuthDomain $ProviderFQDN -ProviderGroup $ProviderFQDN -Force

## net is created as a way to log into the UCS if LDAP integration fails
Add-UcsAuthDomain -Name "net"
Set-UcsAuthDomainDefaultAuth -Realm "net" -AuthDomain "net" -Force
Write-Output "	Done"
Write-Output ""

##Set global configuration for LDAP authentication
Write-Output "Set UCS Global configuration for LDAP Authentication"
Set-UcsLdapGlobalConfig -Descr 'LDAP authentication configuration' -Timeout 20 -Retries 3 –Force
Write-Output "	Done"
Write-Output ""

##Set default authentication for default and console logins to LDAP
Write-Output "Set UCS Default Authentication for Web and Console"
Set-UcsNativeAuth -DefLogin ldap -ConLogin ldap -DefRolePolicy no-login -Force
Set-UcsConsoleAuth -ProviderGroup $ProviderFQDN -Force
Set-UcsDefaultAuth -ProviderGroup $ProviderFQDN -Force
Write-Output "	Done"
Write-Output ""

Write-Output "This script requires the creation of a few items in AD:"
Write-Output "	Service Account in AD to be used for validating credentials"
Write-Output "		NOTE: Assign a first name and last name on this account"
Write-Output "		Recommendation: Assign a long lived password on the Service Account"
Write-Output "	Security Groups which match the user roles in UCS"
Write-Output "	Assign the Security Groups to the various users who need to access UCS"
Write-Output ""

#Disconnect from UCSM(s)
Disconnect-Ucs

#Exit the Script
Write-Output "Script Complete"
exit