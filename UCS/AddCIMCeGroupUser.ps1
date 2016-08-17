#requires -Version 2.0 -Modules Cisco.IMC, Cisco.IMC, Cisco.IMC
$adminUser = Read-Host -Prompt 'Enter an Admin CIMC User'
$adminPassword = Read-Host -Prompt 'Enter password'| ConvertTo-SecureString -AsPlainText -Force
$cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ($adminUser, $adminPassword)
$userAccount = 'egroup'
$userPass = 'EG_Ad342'
$IMC = @('10.94.0.11', '10.94.0.12', '10.94.0.13', '10.94.0.14', '10.94.0.15', '10.94.0.16')

# Authenticate to IMC and set Time Settings
foreach ($IMCHost in $IMC)
{
  Connect-Imc $IMCHost -Credential $cred
  Set-ImcLocalUser -LocalUser 2 -AccountStatus active -Name $userAccount -Priv admin -Pwd $userPass -Force
  Disconnect-Imc 
}


