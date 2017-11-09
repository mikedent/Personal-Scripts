<#
.SYNOPSIS
    Creates a customized version of Powershell ISE 
.DESCRIPTION
    Using multiple additional installed modules, creates a customized version of Powershell ISE .
    The following additional modules are required:
        vSphere PowerCLI - Tested with release 5.5+
        PureStorage PowerShell Toolkit (https://github.com/barkz/PureStoragePowerShellToolkit)- Tested with release 2.8.0.430
        NutanixCmdlets (Obtained from Nutanix Cluster or in Github repo) - Tested with release 1.1.2
        Cisco UCS PowerTool (https://communities.cisco.com/docs/DOC-37154) - Tested with release 1.4.1
        ISESteroids (http://www.powertheshell.com/isesteroids/, and requires license) - Tested with release 2.2.0
.NOTES
    File Name   : Microsoft.PowerShell_profile.ps1
    Author      : Mike Dent
    Date        : 4/27/2016
#>

# Desired Module Definition
$moduleList = @(
  'Cisco.UCSManager', 
  'Cisco.IMC',
  'Zerto.PS.Commands'
)
# Finish Module Definition

# Adding Custom Functions
function LoadModules()
{
  $loaded = Get-Module -Name $moduleList -ErrorAction Ignore | ForEach-Object -Process {
    $_.Name
  }
  $registered = Get-Module -Name $moduleList -ListAvailable -ErrorAction Ignore | ForEach-Object -Process {
    $_.Name
  }
  $notLoaded = $registered | Where-Object -FilterScript {
    $loaded -notcontains $_
  }
   
  foreach ($module in $registered) 
  {
    if ($loaded -notcontains $module) 
    {
      Import-Module $module
    }
  }
}

function tail ($file) 
{
  Get-Content $file -Wait
}

function Reload-Profile 
{
  @(
    $Profile.AllUsersAllHosts, 
    $Profile.AllUsersCurrentHost, 
    $Profile.CurrentUserAllHosts, 
    $Profile.CurrentUserCurrentHost
  ) | ForEach-Object -Process {
    if(Test-Path $_) 
    {
      Write-Verbose -Message "Running $_"
      . $_
    }
  }
}

function Edit-HostsFile 
{
  Start-Process -FilePath notepad -ArgumentList "$env:windir\system32\drivers\etc\hosts"
}
# End of custom functions

# ISESteroids 
Start-Steroids

# NutanixCmdlets 
#Import-Module "C:\Program Files (x86)\Nutanix Inc\NutanixCmdlets\Modules\Common\Common.dll"
#Get-ChildItem -Path 'C:\Program Files (x86)\Nutanix Inc\NutanixCmdlets\Modules' *.dll -recurse | ForEach-Object {Import-Module -Name $_.FullName -WarningAction silentlyContinue -Prefix "NTNX"}

# Load Desired Modules
LoadModules

Set-ExecutionPolicy Bypass -Scope CurrentUser
Set-Location C:\Scripts