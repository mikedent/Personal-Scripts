# PowerCLI Script to Configure DNS and NTP on ESXi Hosts
# PowerCLI Session must be connected to vCenter Server using Connect-VIServer

# Define variables
$vCServer = "10.74.110.23"
$VCUser = "root"
$VCUserPass = 'nutanix/4u'
#Add-PSSnapin VMware.VimAutomation.Core
Connect-VIServer -Server EOCVPVC01.alarm01.local -User administrator@vsphere.local -Password "fbN;bhA8{BPA"

# Prompt for Primary and Alternate DNS Servers
$dnspri = '10.74.96.7'
$dnsalt = '10.30.40.47'

# Prompt for Domain
$domainname = 'alarm01.local'

#Prompt for NTP Servers
$ntpone = '172.23.8.6'
$ntptwo = '172.22.8.6'
$ntpthree = '10.10.45.1'

$esxHosts = get-VMHost

foreach ($esx in $esxHosts) {

   Write-Host "Configuring DNS and Domain Name on $esx" -ForegroundColor Green
   Get-VMHostNetwork -VMHost $esx | Set-VMHostNetwork -DomainName $domainname -DNSAddress $dnspri , $dnsalt -Confirm:$false

   
   Write-Host "Configuring NTP Servers on $esx" -ForegroundColor Green
   Add-VMHostNTPServer -NtpServer $ntpone , $ntptwo, $ntpthree -VMHost $esx -Confirm:$false

 
   Write-Host "Configuring NTP Client Policy on $esx" -ForegroundColor Green
   Get-VMHostService -VMHost $esx | where{$_.Key -eq "ntpd"} | Set-VMHostService -policy "on" -Confirm:$false

   Write-Host "Restarting NTP Client on $esx" -ForegroundColor Green
   Get-VMHostService -VMHost $esx | where{$_.Key -eq "ntpd"} | Restart-VMHostService -Confirm:$false

}
Write-Host "Done!" -ForegroundColor Green

disconnect-viserver * -force