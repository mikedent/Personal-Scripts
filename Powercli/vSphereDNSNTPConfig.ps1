# PowerCLI Script to Configure DNS and NTP on ESXi Hosts
# PowerCLI Session must be connected to vCenter Server using Connect-VIServer

$VIServer = '172.19.52.2'
$User = 'administrator@vsphere.local'
$Pass = '8zMGBHPb#'
#Add-PSSnapin VMware.VimAutomation.Core
Connect-VIServer -Server $VIServer  -User $User -Password $Pass

# Prompt for Primary and Alternate DNS Servers
$dnspri = '172.19.52.254'
$dnsalt = '172.19.51.254'

# Prompt for Domain
$domainname = 'ecscad.local'

#Prompt for NTP Servers
$ntpone = '172.18.14.109'
$ntptwo = '172.18.12.17'

$esxHosts = get-VMHost

foreach ($esx in $esxHosts) {

   Write-Host "Configuring DNS and Domain Name on $esx" -ForegroundColor Green
   Get-VMHostNetwork -VMHost $esx | Set-VMHostNetwork -DomainName $domainname -DNSAddress $dnspri , $dnsalt -Confirm:$false

   
   Write-Host "Configuring NTP Servers on $esx" -ForegroundColor Green
   Add-VMHostNTPServer -NtpServer $ntpone , $ntptwo -VMHost $esx -Confirm:$false

 
   Write-Host "Configuring NTP Client Policy on $esx" -ForegroundColor Green
   Get-VMHostService -VMHost $esx | where{$_.Key -eq "ntpd"} | Set-VMHostService -policy "on" -Confirm:$false

   Write-Host "Restarting NTP Client on $esx" -ForegroundColor Green
   Get-VMHostService -VMHost $esx | where{$_.Key -eq "ntpd"} | Restart-VMHostService -Confirm:$false

}
Write-Host "Done!" -ForegroundColor Green

disconnect-viserver * -force