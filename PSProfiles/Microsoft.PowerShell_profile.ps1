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

# Desired Module Loads below
$moduleList = @(
    "VMware.VimAutomation.Core",
    "VMware.VimAutomation.Vds",
    "VMware.VimAutomation.Cloud",
    "VMware.VimAutomation.PCloud",
    "VMware.VimAutomation.Cis.Core",
    "VMware.VimAutomation.Storage",
    "VMware.VimAutomation.HA",
    "VMware.VimAutomation.vROps",
    "VMware.VumAutomation",
    "VMware.VimAutomation.License",
    "Cisco.UCSManager",
    "Cisco.IMC")
    
# ISESteroids 
Start-Steroids

# NutanixCmdlets 
Import-Module "C:\Program Files (x86)\Nutanix Inc\NutanixCmdlets\Modules\Common\Common.dll"
#Get-ChildItem -Path 'C:\Program Files (x86)\Nutanix Inc\NutanixCmdlets\Modules' *.dll -recurse | ForEach-Object {Import-Module -Name $_.FullName -WarningAction silentlyContinue -Prefix "NTNX"}

# Finish Module Loads

# Adding Custom Functions

# Load modules
function LoadModules(){
   
   $loaded = Get-Module -Name $moduleList -ErrorAction Ignore | % {$_.Name}
   $registered = Get-Module -Name $moduleList -ListAvailable -ErrorAction Ignore | % {$_.Name}
   $notLoaded = $registered | ? {$loaded -notcontains $_}
 
   
   foreach ($module in $registered) {
      if ($loaded -notcontains $module) {
		 Import-Module $module
      }
   }
}

function tail ($file) {
	Get-Content $file -Wait
}

function Reload-Profile {
    @(
        $Profile.AllUsersAllHosts,
        $Profile.AllUsersCurrentHost,
        $Profile.CurrentUserAllHosts,
        $Profile.CurrentUserCurrentHost
    ) | % {
        if(Test-Path $_) {
            Write-Verbose "Running $_"
            . $_
        }
    }
}

function Edit-HostsFile {
    Start-Process -FilePath notepad -ArgumentList "$env:windir\system32\drivers\etc\hosts"
}

# End of custom functions
LoadModules