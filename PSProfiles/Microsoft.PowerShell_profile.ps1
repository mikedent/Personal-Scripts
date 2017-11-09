<#
    .SYNOPSIS
    Creates a customized version of powershell
    .DESCRIPTION
    Using multiple additional installed modules, creates a customized version of the powershell console.
    The following additional modules are required:
    vSphere PowerCLI - Tested with release 5.5+
    PureStorage PowerShell Toolkit (https://github.com/barkz/PureStoragePowerShellToolkit)- Tested with release 2.8.0.430
    NutanixCmdlets (Obtained from Nutanix Cluster or in Github repo) - Tested with release 1.1.2
    Cisco UCS PowerTool (https://communities.cisco.com/docs/DOC-37154) - Tested with release 1.4.1
    .NOTES
    File Name   : Microsoft.PowerShell_profile.ps1
    Author      : Mike Dent
    Date        : 7/3/2015
#>

# Desired Module Definition
$moduleList = @(
  'Cisco.UCSManager', 
  'Cisco.IMC'
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

# Begin Load of profile

LoadModules
Add-PSSnapin Nutanix*
Add-PSSnapin Zerto*
Set-ExecutionPolicy Bypass -Scope CurrentUser
Set-Location C:\Scripts