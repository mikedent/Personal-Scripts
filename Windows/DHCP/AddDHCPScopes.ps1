#requires -Version 1 -Modules DhcpServer

<#

        Author: Mike Dent
        Version: 1.1
        Version History:  
        1.0: Created script
        1.1: Modified FOREACH loop to use objects directly from .csv rather than defining each
             Added each DHCP Scope to existing replication configuration, and initated replication of scope 

        Purpose:  Add DHCP Scopes to environment that include VOIP VLANs

#>


$dhcpServer = 'flodhcp-01.fcty.gov'
$ciscoTFTP = @('10.105.215.10', '10.105.15.10', '10.255.115.10')
$dhcpFile = 'dhcpscopes.csv'
$dhcpFailover = Get-DhcpServerv4Failover | Select-Object -Property Name
$dhcpPartner = Get-DhcpServerv4Failover | Select-Object -Property PartnerServer

$dhcpScopes = Import-Csv $dhcpFile
foreach ($Scope in $DHCPScopes) 
{
    # Adds each line in the DHCPScopes.csv file to a new dhcp scope
    Write-Host  'Creating DHCP Scope for: '$Scope.name
    Add-DhcpServerv4Scope -Name $Scope.name -Description $Scope.description -StartRange $Scope.startrange -EndRange $Scope.endrange -SubnetMask $Scope.subnetmask
    Set-DhcpServerv4OptionValue -ScopeId $Scope.scopeid -Router $Scope.router
    if ('1' -eq $Scope.voip)
    
    {Set-DhcpServerv4OptionValue -OptionId 150 -ScopeId $Scope.scopeid -Value $ciscoTFTP}
    # Adds each DHCP Scope to the existing Failover relationship, and initiates replication
    Add-DhcpServerv4FailoverScope -Name $dhcpFailover.Name -ScopeId $Scope.scopeid
    Invoke-DhcpServerv4FailoverReplication  -ScopeId $Scope.scopeid
}
