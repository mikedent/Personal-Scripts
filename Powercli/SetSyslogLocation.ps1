<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2015 v4.2.82
	 Created on:   	4/22/2015 5:55 PM
	 Created by:   	Mike
	 Organization: 	
	 Filename:     	
	===========================================================================
	.DESCRIPTION
		A description of the file.
#>

# Set vSphere

$vSphereServer = Read-Host "Enter the vCenter Server"
$SyslogServer = Read-Host "Enter the Syslog Server"

# Set Logging Settings
#$logHost = "udp://$logServer:514"
#$logSize = "10240" #10mb
#$logRotate = "20"

################################# start functions

#################################
#check vmware powercli is registered. PowerCLI must be installed.
Function Add-PowerCLI
{
    $snapinInstalled = Get-PSSnapin -registered
    if ($snapinInstalled -like "*VimAuto*")
    {
        Write-host "PowerCLI installed"
    }
    Else
    {
        write-host "PowerCLI not installed....installing"
        Add-PSSnapin "Vmware.VimAutomation.Core"
        if ($? -eq $FALSE)
        {
            write-host "PowerCLI is not installed - Please install.......quiting"
            exit
        }
    }
}

Function Check-Error ($name)
{
    if ($? -eq $FALSE)
    {
        write-host "$name failed" -ForegroundColor Red
    }
    else
    {
        write-host "$name succeeded" -ForegroundColor Green
    }
}
function Set-VMHostLogs ($vSphereServer,$logHost,$logSize,$logRotate)
{

} 

function Get-VMHostsLogs ($esxHost)
{
    $readLogHost = Get-VMHostAdvancedConfiguration -VMHost $esxHost -Name Syslog.global.logHost
    $readDefaultSize = Get-VMHostAdvancedConfiguration -VMHost $esxHost -Name Syslog.global.defaultsize
    $readRotate = Get-VMHostAdvancedConfiguration -VMHost $esxHost -Name Syslog.global.defaultRotate
    write-host $esxHost $readLogHost.keys $readLogHost.Values
    write-host $esxHost $readDefaultSize.keys $readDefaultSize.Values
    write-host $esxHost $readRotate.keys $readRotate.Values
}

################################# End functions

#################################
# Start Main Script 

Add-PowerCLI

Connect-VIServer $vSphereServer
$erroractionpreference = "SilentlyContinue"
#get list of hosts from vsphere(esxi)

$vmHosts = get-vmhost
#connect to each individual host
#foreach ($esxHost in $vmHosts) #loops through all hosts on this vsphere
<#{
    $esxHost.name

    $esxCLI = Get-EsxCli -vmhost $esxHost #connect to esxCLI
    #if unable to set using set-vmhostadvancedconfigurations, fallback to esxCLI using the following:
    #system.syslog.config.set(long defaultrotate, long defaultsize, string logdir, boolean logdirunique, string loghost, string reset
    Set-VMHostAdvancedConfiguration -VMHost $esxHost -Name Syslog.global.logHost -value $logHost
    write-host "Setting LogHost for $esxHost to $logHost"
    Check-Error "Set LogHost"

    #Set-VMHostAdvancedConfiguration -VMHost $esxHost -Name Syslog.global.defaultsize -value $logSize
    #unable to set via Set-VMHostAdvancedConfiguration - using esxCLI command
    $esxCLI.system.syslog.config.set($NULL,$logSize)
    write-host "Setting LogHost for $esxHost to $logHost"
    Check-Error "Set Log Default Size"
    Set-VMHostAdvancedConfiguration -VMHost $esxHost -Name Syslog.global.defaultRotate -value $logRotate
    write-host "Setting LogHost for $esxHost to $logHost"
    Check-Error "Set Log Rotate"
}#>

foreach ($esxHost in $vmHosts) #loops through all hosts on this vsphere
{
	Write-Host “Adding $SyslogServer as Syslog server for $($_.Name)”
	$SetSyslog = Set-VMHostSysLogServer -SysLogServer $SyslogServer -SysLogServerPort 514 -VMHost $_
	Write-Host “Reloading Syslog on $($_.Name)”
	$Reload = (Get-ESXCLI -VMHost $_).System.Syslog.reload()
	Write-Host “Setting firewall to allow Syslog out of $($_)”
	$FW = $_ | Get-VMHostFirewallException | Where { $_.Name -eq ‘syslog’ } | Set-VMHostFirewallException -Enabled:$true
}
