# PowerCLI Script to Configure DNS and NTP on ESXi Hosts
# PowerCLI Session must be connected to vCenter Server using Connect-VIServer

# Define variables
$vCServer = "labvcsa.etherbacon.net"
$VCUser = "administrator@vsphere.local"
$VCUserPass = 'G0lden*ak'
#Add-PSSnapin VMware.VimAutomation.Core
Connect-VIServer -Server $VCServer  -User $VCUser -Password $VCUserPass

# Prompt for Primary and Alternate DNS Servers
$dnspri = '10.10.20.254'
$dnsalt = '10.10.201.254'

# Prompt for Domain
$domainname = 'etherbacon.net'

#Prompt for NTP Servers
$ntpone = 'time.etherbacon.net'
$ntptwo = 'time.nist.gov'

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