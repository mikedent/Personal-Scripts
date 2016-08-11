#requires -Version 1
#requires -PSSnapin VMware.VimAutomation.Core
$VIServer = '10.91.0.23'
$User = 'root'
$Pass = 'Tr!t3cH1'
#Add-PSSnapin VMware.VimAutomation.Core
Connect-VIServer -Server $VIServer  -User $User -Password $Pass
$targets = '10.255.253.60', '10.255.254.60', '10.255.253.61', '10.255.254.61'
$ESXiHosts  = Get-VMHost
foreach ($esx in $ESXiHosts) 
{
  $hba = $esx |
  Get-VMHostHba -Type iScsi |
  Where-Object -FilterScript {
    $_.Model -eq 'iSCSI Software Adapter'
  }
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
disconnect-viserver *