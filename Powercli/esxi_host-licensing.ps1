# ESXi Host Licensing
# Set Variables to be used in the ESXi Host configuration
#
# Modify these settings for regional requirements
#

# Enter each of the ESXi hosts/root password in the $hosts variable below
$hosts="10.200.50.187","10.200.50.117","10.200.50.31"
$HostPassword=Read-Host "Enter the root password"
$License = "JN421-4730P-L8Q4X-0J9HH-A9940"

# Authenticate to ESX Host.
foreach ($vhost in $hosts){
  Connect-VIServer $vhost -User root -Password $HostPassword
  $licMgr = Get-View -Id 'LicenseManager-ha-license-manager'
  $licMgr.UpdateLicense($License, $null)
  Disconnect-VIServer -Confirm:$False
}
