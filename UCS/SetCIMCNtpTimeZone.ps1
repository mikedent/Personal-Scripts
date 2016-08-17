#requires -Version 2 -Modules Cisco.IMC
$user = Read-Host -Prompt 'Enter an Admin CIMC User'
$password = Read-Host -Prompt 'Enter password'| ConvertTo-SecureString -AsPlainText -Force
$cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ($user, $password)
$IMC = @('10.94.0.11', '10.94.0.12', '10.94.0.13', '10.94.0.14','10.94.0.15','10.94.0.16')
$NTPServer = '10.255.255.225'

# Authenticate to IMC and set Time Settings
foreach ($IMCHost in $IMC)
{
  Connect-Imc $IMCHost -Credential $cred
  Set-ImcNtpServer -NtpEnable Yes -NtpServer1 $NTPServer -Force
  Set-ImcTopSystem -TimeZone 'America/New York' -Force
  Disconnect-Imc
}


