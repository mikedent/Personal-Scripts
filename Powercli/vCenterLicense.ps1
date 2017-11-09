
<#

    Author:
    Version:
    Version History:

    Purpose:

#>


$DefaultVIServer = '10.105.141.11'
$vcuser = 'administrator@vsphere.local'
$vcpass = 'E911@dmin!'
$license = 'H06A5-0C0E0-K859Z-0HCHP-0E6QJ'

Function Add_License_to_vCenter {

  # Get value passed to function
  $LicKey = $args[0]

  # add PowerCLI snapins
  add-PSSnapin VMware.VimAutomation.Core
  add-PSSnapin VMware.VimAutomation.License

  # Connect to vCenter
  Connect-VIServer $DefaultVIServer -user $vcuser -password $vcpass

  #Add Licenses
  $VcLicMgr=$DefaultVIServer
  $LicMgr = Get-View $VcLicMgr
  $AddLic= Get-View $LicMgr.Content.LicenseManager

  $AddLic.AddLicense($LicKey,$null)

  # Disconnect from vCenter
  Disconnect-VIServer -Confirm:$false

}
add_license_to_vcenter($license)
