<#
.SYNOPSIS
    Microsoft.PowerShell_profile.ps1 - My PowerShell profile
.DESCRIPTION
    Microsoft.PowerShell_profile - Customizes the PowerShell console
.NOTES
    File Name   : Microsoft.PowerShell_profile.ps1
    Author      : Mike Dent
#>

# Desired Module Loads below

# vSphere PowerCLI
Import-Module -name VMware.VimAutomation.Cis.Core
Import-Module -name VMware.VimAutomation.Core
Import-Module -name VMware.VimAutomation.HA
Import-Module -name VMware.VimAutomation.SDK
Import-Module -name VMware.VimAutomation.Storage
Import-Module -name VMware.VimAutomation.Vds
# PureStorage PowerShell 
Import-Module PureStoragePowerShell
# NutanixCmdlets 
#Import-Module "C:\Program Files (x86)\Nutanix Inc\NutanixCmdlets\Modules\Common\Common.dll"
#Get-ChildItem -Path "C:\Program Files (x86)\Nutanix Inc\NutanixCmdlets\Modules" *.dll -recurse | ForEach-Object {Import-Module -Name $_.FullName -WarningAction silentlyContinue -Prefix "NTNX"}
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