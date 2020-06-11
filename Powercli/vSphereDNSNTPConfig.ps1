# PowerCLI Script to Configure DNS and NTP on ESXi Hosts
# PowerCLI Session must be connected to vCenter Server using Connect-VIServer

# Define variables
$vCServer = "10.200.82.138"
$cluster = "ACC"
$VCUser = "administrator@vsphere.local"
$VCUserPass = 'TTka-2eN!e3*'
#Add-PSSnapin VMware.VimAutomation.Core
Connect-VIServer -Server $vCServer -User $VCUser -Password $VCUserPass

# Prompt for Primary and Alternate DNS Servers
$dnspri = '10.200.82.254'			
$dnsalt = '10.200.80.254'

# Prompt for Domain
$domainname = 'baltcad.city'

#Prompt for NTP Servers
$ntpone = '10.200.82.254'
$ntptwo = '10.200.80.254'
#$ntpthree = 'time.google.com'
#$ntpfour = '0.us.pool.ntp.org'

$esxHosts = Get-Cluster $cluster | Get-VMhost

foreach ($esx in $esxHosts) {

   Write-Host "Configuring DNS and Domain Name on $esx" -ForegroundColor Green
   Get-VMHostNetwork -VMHost $esx | Set-VMHostNetwork -DomainName $domainname -SearchDomain $domainname -DNSAddress $dnspri , $dnsalt -Confirm:$false

   
   Write-Host "Configuring NTP Servers on $esx" -ForegroundColor Green
   Add-VMHostNTPServer -NtpServer $ntpone , $ntptwo -VMHost $esx -Confirm:$false

 
   Write-Host "Configuring NTP Client Policy on $esx" -ForegroundColor Green
   Get-VMHostService -VMHost $esx | where{$_.Key -eq "ntpd"} | Set-VMHostService -policy "on" -Confirm:$false

   Write-Host "Restarting NTP Client on $esx" -ForegroundColor Green
   Get-VMHostService -VMHost $esx | where{$_.Key -eq "ntpd"} | Restart-VMHostService -Confirm:$false

}
Write-Host "Done!" -ForegroundColor Green

disconnect-viserver * -force