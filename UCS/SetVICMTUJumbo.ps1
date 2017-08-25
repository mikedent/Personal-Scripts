#requires -Version 2 -Modules Cisco.IMC
$user = Read-Host -Prompt 'Enter an Admin CIMC User'
$password = Read-Host -Prompt 'Enter password'| ConvertTo-SecureString -AsPlainText -Force
$cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ($user, $password)
$IMC = @('192.168.200.35')

# Authenticate to IMC and set Time Settings
foreach ($IMCHost in $IMC)
{
  Connect-Imc $IMCHost -Credential $cred
  Get-ImcAdaptorHostEthIf | Set-ImcAdaptorHostEthIf -Mtu '9000'
  Disconnect-Imc
}

Get-ImcAdapatorHostEthIf