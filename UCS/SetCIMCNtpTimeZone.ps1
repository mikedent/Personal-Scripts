#requires -Version 2 -Modules Cisco.IMC
$user = Read-Host -Prompt 'Enter an Admin CIMC User'
$password = Read-Host -Prompt 'Enter password'| ConvertTo-SecureString -AsPlainText -Force
$cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ($user, $password)
$IMC = @('192.168.200.33','192.168.200.34','192.168.200.35')
$NTPServer = '192.168.253.194'

# Authenticate to IMC and set Time Settings
foreach ($IMCHost in $IMC)
{
  Connect-Imc $IMCHost -Credential $cred
  Set-ImcNtpServer -NtpEnable Yes -NtpServer1 $NTPServer -Force
  Set-ImcTopSystem -TimeZone 'America/Los Angeles' -Force
  Disconnect-Imc
}


