
<#

    Author:  Mike Dent
    Version:  1.0
    Version History:

    Purpose:  Set a Static/DHCP Address on ethernet adapter

#>

# Check to see if we're using RunAs, and if not pass to new RunAs cmd window
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator'))
{   
  $arguments = "& '" + $myinvocation.mycommand.definition + "'"
  Start-Process -FilePath powershell -Verb runAs -ArgumentList $arguments
  Break
}

$SetIP = Read-Host -Prompt 'Enter 1 to set a Static IP, enter 2 to set adapter to DHCP'


if ($SetIP -eq 1)
{
  #requires -Version 2 -Modules DnsClient, NetAdapter, NetTCPIP
  $IP = Read-Host -Prompt 'Enter the new IP Address'
  $MaskBits = Read-Host -Prompt 'Enter the Mask Bits - 24 = This means subnet mask = 255.255.255.0'
  $Gateway = Read-Host -Prompt 'Enter the Gateway'
  $Dns = Read-Host -Prompt 'Enter a DNS Server'
  $IPType = 'IPv4'

  # Retrieve the network adapter that you want to configure
  $adapter = Get-NetAdapter | Where-Object -FilterScript {
    $_.Status -eq 'up'
  }

  # Remove any existing IP, gateway from our ipv4 adapter
  If (($adapter | Get-NetIPConfiguration).IPv4Address.IPAddress) 
  {
    $adapter | Remove-NetIPAddress -AddressFamily $IPType -Confirm:$false
  }

  If (($adapter | Get-NetIPConfiguration).Ipv4DefaultGateway) 
  {
    $adapter | Remove-NetRoute -AddressFamily $IPType -Confirm:$false
  }

  # Configure the IP address and default gateway
  $adapter | New-NetIPAddress -AddressFamily $IPType -IPAddress $IP -PrefixLength $MaskBits -DefaultGateway $Gateway

  # Configure the DNS client server IP addresses
  $adapter | Set-DnsClientServerAddress -ServerAddresses $Dns
}
elseif ($SetIP -eq 2)
{
  $IPType = 'IPv4'
  $adapter = Get-NetAdapter | Where-Object -FilterScript {
    $_.Status -eq 'up'
  }
  $interface = $adapter | Get-NetIPInterface -AddressFamily $IPType

  If ($interface.Dhcp -eq 'Disabled') 
  {
    # Remove existing gateway
    If (($interface | Get-NetIPConfiguration).Ipv4DefaultGateway) 
    {
      $interface | Remove-NetRoute -Confirm:$false
    }

    # Enable DHCP
    $interface | Set-NetIPInterface -Dhcp Enabled

    # Configure the  DNS Servers automatically
    $interface | Set-DnsClientServerAddress -ResetServerAddresses
  }
  else 
  {
    Write-Host -Object 'Not checking host wide settings for XCOPY and In-Guest UNMAP due to in-script override'
  }
}


