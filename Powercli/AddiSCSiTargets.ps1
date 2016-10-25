$VIServer = '10.94.0.26'
$User = 'root'
$Pass = 'Tr!t3cH1'
$iSCSIAddressA = '10.255.254.26'
$iSCSIAddressB = '10.255.255.26'
$iSCSIAVlan = '920'
$iSCSIBVlan = '925'
$subnetMask = '255.255.255.0'
$MTU = '9000'
# Network Parameters
$VmnicInterface = @(
  'vmnic0', 
  'vmnic1', 
  'vmnic8', 
  'vmnic9'
)
#Add-PSSnapin VMware.VimAutomation.Core
Connect-VIServer -Server $VIServer  -User $User -Password $Pass
$targets = '10.255.253.60', '10.255.254.60', '10.255.253.61', '10.255.254.61'
$ESXiHosts  = Get-VMHost
$ISCSIvSwitch = 'vSwitch1'

# Create iSCSI A and B Port Groups
New-VirtualPortGroup -VirtualSwitch $ISCSIvSwitch -Name 'iSCSI-A' -VLanId $iSCSIAVlan
New-VirtualPortGroup -VirtualSwitch $ISCSIvSwitch -Name 'iSCSI-B' -VLanId $iSCSIBVlan 
    
#Create VMKernel ports for iSCSI traffic on the new portgroups
$VMKernel1 = New-VMHostNetworkAdapter -VirtualSwitch $ISCSIvSwitch -PortGroup 'iSCSI-A' -IP $iSCSIAddressA -SubnetMask $subnetMask -Mtu $MTU
$VMKernel2 = New-VMHostNetworkAdapter -VirtualSwitch $ISCSIvSwitch -PortGroup 'iSCSI-B' -IP $iSCSIAddressB -SubnetMask $subnetMask -Mtu $MTU

#Set the Active and Unused uplinks / vmnics
Get-VirtualPortGroup  -VirtualSwitch $ISCSIvSwitch -Name 'iSCSI-A' |
Get-NicTeamingPolicy |
Set-NicTeamingPolicy -MakeNicActive $VmnicInterface[1] -MakeNicUnused $VmnicInterface[3]
Get-VirtualPortGroup  -VirtualSwitch $ISCSIvSwitch -Name 'iSCSI-B' |
Get-NicTeamingPolicy |
Set-NicTeamingPolicy -MakeNicActive $VmnicInterface[3] -MakeNicUnused $VmnicInterface[1]

foreach ($esx in $ESXiHosts) 
{
  # Check for iSCSi initiator and add if doesn't exist
  $hba = Get-VMHostHba -VMHost $Hostname -Type iScsi | Where-Object -FilterScript {
    $_.Model -eq 'iSCSI Software Adapter'
  }
      
  #Check to see if no adapters were found in the last cmdlet. If there are no results, enable the iSCSI Software Adapter on the ESXi Host
  if (!$hba)
  {
    #Enable the iSCSI Software Adapter
    Get-VMHostStorage $Hostname | Set-VMHostStorage -SoftwareIScsiEnabled $True
    $hba = Get-VMHostHba -VMHost $Hostname -Type iScsi | Where-Object -FilterScript {
      $_.Model -eq 'iSCSI Software Adapter'
    }
  }
  #Sets up PowerCLI to be able to access esxcli commands
  $esxcli = Get-EsxCli 

  #Binds VMKernel ports created earlier to the iSCSI Software Adapter HBA
  $esxcli.iscsi.networkportal.add($hba.device,$null,$VMKernel1.Name)
  $esxcli.iscsi.networkportal.add($hba.device,$null,$VMKernel2.Name)

  foreach ($target in $targets) 
  {
    # Check to see if the SendTarget exist, if not add it
    if (Get-IScsiHbaTarget -IScsiHba $hba -Type Send | Where-Object -FilterScript {
        $_.Address -cmatch $target
    }) 
    {
      Write-Host -Object "The target $target does exist on $esx" -ForegroundColor Green
    }
    else 
    {
      Write-Host -Object "The target $target doesn't exist on $esx" -ForegroundColor Red
      Write-Host -Object "Creating $target on $esx ..." -ForegroundColor Yellow
      New-IScsiHbaTarget -IScsiHba $hba -Address $target       
    }
  }
}
Disconnect-VIServer -Server * -Confirm:$false -Force