# Check to see if we're using RunAs, and if not pass to new RunAs cmd window
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator'))
{   
  $arguments = "& '" + $myinvocation.mycommand.definition + "'"
  Start-Process -FilePath powershell -Verb runAs -ArgumentList $arguments
  Break
}

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