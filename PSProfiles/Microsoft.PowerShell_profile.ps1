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

# Start of importing Modules
# vSphere PowerCLI
Import-Module -name VMware.VimAutomation.Cis.Core
Import-Module -name VMware.VimAutomation.Core
Import-Module -name VMware.VimAutomation.HA
Import-Module -name VMware.VimAutomation.SDK
Import-Module -name VMware.VimAutomation.Storage
Import-Module -name VMware.VimAutomation.Vds
# NutanixCmdlets
Import-Module "C:\Program Files (x86)\Nutanix Inc\NutanixCmdlets\Modules\Common\Common.dll"
Get-ChildItem -Path "C:\Program Files (x86)\Nutanix Inc\NutanixCmdlets\Modules" *.dll -recurse | ForEach-Object {Import-Module -Name $_.FullName -WarningAction silentlyContinue -Prefix "NTNX"}
# Cisco UCS
Import-Module -Name CiscoUCSPS
# Finish Module Loads

# Adding Custom Functions
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