# PowerCLI Script to Configure DNS and NTP on ESXi Hosts
# PowerCLI Session must be connected to vCenter Server using Connect-VIServer

# Define variables
$vCServer = "172.30.79.35"
$VCUser = "root"
$VCUserPass = 'nutanix/4u'
#Add-PSSnapin VMware.VimAutomation.Core
Connect-VIServer -Server $vCServer -User $VCUser -Password $VCUserPass

# Prompt for Primary and Alternate DNS Servers
$dnspri = '172.31.63.120'
$dnsalt = '172.31.112.200'

# Prompt for Domain
$domainname = 'cchnl.hnl'

#Prompt for NTP Servers
$ntpone = '1.1.1.254'
$ntptwo = '1.1.2.254'
$ntpthree = 'time.google.com'

$esxHosts = get-VMHost

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