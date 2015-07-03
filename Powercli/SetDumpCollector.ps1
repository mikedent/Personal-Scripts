<#
.SYNOPSIS
  Script to create vSphere Datacenter and Cluster, and add hosts to Cluster

.DESCRIPTION
   The script does the following:
        1. Creates the Data Center and Cluster with default HA/DRS settings
        2. Adds ESXi hosts to the newly created cluster
        # Parameter Descriptions

.PARAMETER VISERVER
vCenter Server to use to configure hosts

.PARAMETER VCCRED
Credentials for access to vCenter

.PARAMETER DATACENTER
Name of Datacenter to Create

.PARAMETER CLUSTER
Name of Cluster to Create

.PARAMETER CLUSTERCONFIG
Cluster Settings based on licensing>

.INPUTS
  <Inputs if any, otherwise state None>

.OUTPUTS
  <Outputs if any, otherwise state None - example: Log file stored in C:\Windows\Temp\<name>.log>

.NOTES
  Version:        1.0
  Author:         Mike Dent
  Creation Date:  6/11/2015
  Purpose/Change: Initial script development
  
.EXAMPLE
  <Example goes here. Repeat this attribute for more than one example>
#>

#-----------------------------------------------------------[ Begin Edit]---------------------------------------------------------
$vCenter = Read-Host "Enter vCenter Address" # Can also change this to be hardcoded
$vCenterCreds = Get-Credential -Message "Enter credentials to connect to vSphere Server or Host"
$esxhosts = "10.10.92.32","10.10.92.33","10.10.92.46"
#-----------------------------------------------------------[ End Edit ]-----------------------------------------------------------


#-----------------------------------------------------------[Functions]------------------------------------------------------------
Function Test-CommandExists
{
    Param ($command)
    $oldPreference = $ErrorActionPreference
    $ErrorActionPreference = 'stop'
    try {if(Get-Command $command){RETURN $true}}
    Catch {Write-Host "$command does not exist"; RETURN $false}
    Finally {$ErrorActionPreference=$oldPreference}

} #end function test-CommandExists

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
#-------------------------------------------------------[ End Functions ]----------------------------------------------------------

#-----------------------------------------------------------[Execution]------------------------------------------------------------
# Connect to vCenter
connect-viserver $vCenter -Credential $vCenterCreds

# Test for Function existence, if exists set Dump Collector
if(Test-CommandExists Set-VMHostDumpCollector){
    foreach ($esx in $esxhosts) {
        Write-Host "Configuring Dump Collector on host $esx to $vCenter" -ForegroundColor green
        Set-VMHostDumpCollector -HostVNic "vmk0" -NetworkServerIP $vCenter -NetworkServerPort 6500 -VMHost $esx
    }
}
else{
    Write-Host "Set-VMHostDumpCollector Function not found.  Please run setup"
}
Write-Host "Configuring Dump Collector service on hosts complete!"

Disconnect-VIServer * -confirm:$false


