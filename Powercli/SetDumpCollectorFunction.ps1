<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2015 v4.2.82
	 Created on:   	4/22/2015 5:47 PM
	 Created by:   	Mike
	 Organization: 	
	 Filename:     	
	===========================================================================
	.DESCRIPTION
		A description of the file.
#>


function Get-VMHostDumpCollector
{
<#
 .SYNOPSIS
 Function to get the Dump Collector config of a VMHost.

 .DESCRIPTION
 Function to get the Dump Collector config of a VMHost.

 .PARAMETER VMHost
 VMHost to configure Dump Collector settings for.

.INPUTS
 String.
 System.Management.Automation.PSObject.

.OUTPUTS
 System.Management.Automation.PSObject.

.EXAMPLE
 PS> Get-VMHostDumpCollector -VMHost ESXi01

 .EXAMPLE
 PS> Get-VMHost ESXi01,ESXi02 | Get-VMHostDumpCollector
#>
	[CmdletBinding()][OutputType('System.Management.Automation.PSObject')]
	
	Param
	(
		
		[parameter(Mandatory = $true, ValueFromPipeline = $true)]
		[ValidateNotNullOrEmpty()]
		[PSObject[]]$VMHost
	)
	
	begin
	{
		
		$DumpCollectorObject = @()
	}
	
	process
	{
		
		foreach ($ESXiHost in $VMHost)
		{
			
			try
			{
				
				if ($ESXiHost.GetType().Name -eq "string")
				{
					
					try
					{
						$ESXiHost = Get-VMHost $ESXiHost -ErrorAction Stop
					}
					catch [Exception]{
						Write-Warning "VMHost $ESXiHost does not exist"
					}
				}
				
				elseif ($ESXiHost -isnot [VMware.VimAutomation.ViCore.Impl.V1.Inventory.VMHostImpl])
				{
					Write-Warning "You did not pass a string or a VMHost object"
					Return
				}
				
				# --- Get Dump Collector Config via ESXCli
				
				$ESXCli = Get-EsxCli -VMHost $ESXiHost
				
				$DumpCollector = $ESXCli.System.Coredump.Network.Get()
				
				$hash = @{
					
					VMHost = $ESXiHost
					HostVNic = $DumpCollector.HostVNic
					NetworkServerIP = $DumpCollector.NetworkServerIP
					NetworkServerPort = $DumpCollector.NetworkServerPort
					Enabled = $DumpCollector.Enabled
				}
				$Object = New-Object PSObject -Property $hash
				$DumpCollectorObject += $Object
				
			}
			catch [Exception]{
				
				throw "Unable to get Dump Collector config"
			}
		}
	}
	end
	{
		
		Write-Output $DumpCollectorObject
	}
}

function Set-VMHostDumpCollector
{
<#
 .SYNOPSIS
 Function to set the Dump Collector config of a VMHost.

 .DESCRIPTION
 Function to set the Dump Collector config of a VMHost.

 .PARAMETER VMHost
 VMHost to configure Dump Collector settings for.

.PARAMETER HostVNic
 VNic to use

.PARAMETER NetworkServerIP
 IP of the Dump Collector

.PARAMETER NetworkServerPort
 Port of the Dump Collector

.INPUTS
 String.
 System.Management.Automation.PSObject.

.OUTPUTS
 None.

.EXAMPLE
 PS> Set-VMHostDumpCollector -HostVNic "vmk0" -NetworkServerIP "192.168.0.100" -NetworkServerPort 6500 -VMHost ESXi01

 .EXAMPLE
 PS> Get-VMHost ESXi01,ESXi02 | Set-VMHostDumpCollector -HostVNic "vmk0" -NetworkServerIP "192.168.0.100" -NetworkServerPort 6500
#>
	[CmdletBinding()]
	
	Param
	(
		
		[parameter(Mandatory = $true, ValueFromPipeline = $true)]
		[ValidateNotNullOrEmpty()]
		[PSObject[]]$VMHost,
		
		[parameter(Mandatory = $true, ValueFromPipeline = $false)]
		[ValidateNotNullOrEmpty()]
		[String]$HostVNic,
		
		[parameter(Mandatory = $true, ValueFromPipeline = $false)]
		[ValidateNotNullOrEmpty()]
		[String]$NetworkServerIP,
		
		[parameter(Mandatory = $true, ValueFromPipeline = $false)]
		[ValidateNotNullOrEmpty()]
		[int]$NetworkServerPort
	)
	
	begin
	{
		
	}
	
	process
	{
		
		foreach ($ESXiHost in $VMHost)
		{
			
			try
			{
				
				if ($ESXiHost.GetType().Name -eq "string")
				{
					
					try
					{
						$ESXiHost = Get-VMHost $ESXiHost -ErrorAction Stop
					}
					catch [Exception]{
						Write-Warning "VMHost $ESXiHost does not exist"
					}
				}
				
				elseif ($ESXiHost -isnot [VMware.VimAutomation.ViCore.Impl.V1.Inventory.VMHostImpl])
				{
					Write-Warning "You did not pass a string or a VMHost object"
					Return
				}
				
				# --- Set the Dump Collector config via ESXCli
				Write-Verbose "Setting Dump Collector config for $ESXiHost"
				$ESXCli = Get-EsxCli -VMHost $ESXiHost
				
				$ESXCli.System.Coredump.Network.Set($null, $HostVNic, $NetworkServerIP, $NetworkServerPort) | Out-Null
				$ESXCli.System.Coredump.Network.Set($true) | Out-Null
				
				Write-Verbose "Successfully Set Dump Collector config for $ESXiHost"
			}
			catch [Exception]{
				
				throw "Unable to set Dump Collector config"
			}
		}
	}
	end
	{
		
	}
}
#
#Get Dump Collector Settings:
#Get-VMHost | Get-VMHostDumpCollector | Format-Table VMHost, HostVNic, NetworkServerIP, NetworkServerPort, Enabled -Auto
#
#Set Dump Collector Settings:
#Get-VMHost | Set-VMHostDumpCollector -HostVNic "vmk0" -NetworkServerIP “10.105.20.101" -NetworkServerPort 6500