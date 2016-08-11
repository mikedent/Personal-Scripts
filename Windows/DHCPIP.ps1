# Check to see if we're using RunAs, and if not pass to new RunAs cmd window
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator'))

{   
  $arguments = "& '" + $myinvocation.mycommand.definition + "'"
  Start-Process -FilePath powershell -Verb runAs -ArgumentList $arguments
  Break
}

#requires -Version 2 -Modules DnsClient, NetAdapter, NetTCPIP
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
