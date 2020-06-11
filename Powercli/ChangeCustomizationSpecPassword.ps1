$VCenterServer = Read-Host "Enter the VCenter Server Name"
$LocalAdminPass = Read-Host "Enter the Local Admin Password" -AsSecureString
$DomainPass = Read-Host "Enter the Windows Domain Password" -AsSecureString

Connect-VIServer $VCenterServer -Credential (Get-Credential -Message "Enter your VCenter Credentials")

$CustSpecs = Get-OSCustomizationSpec | Select -ExpandProperty name

Foreach ($CustSpec in $CustSpecs){
Set-OSCustomizationSpec -OSCustomizationSpec $CustSpec -AdminPassword $LocalAdminPass -DomainPassword $DomainPass
  }

Disconnect-VIServer -Confirm:$false -Force