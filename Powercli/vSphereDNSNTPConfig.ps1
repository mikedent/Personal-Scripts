# PowerCLI Script to Configure DNS and NTP on ESXi Hosts
# PowerCLI Session must be connected to vCenter Server using Connect-VIServer

# Define variables
$vCServer = "jdvct01.jeffcom.local"
$VCUser = "administrator@vsphere.local"
$VCUserPass = 'Tr!t3cH1'
#Add-PSSnapin VMware.VimAutomation.Core
Connect-VIServer -Server $VCServer  -User $VCUser -Password $VCUserPass

# Prompt for Primary and Alternate DNS Servers
$dnspri = '10.73.82.81'
$dnsalt = '10.73.82.80'

# Prompt for Domain
$domainname = 'jeffcom.local'

#Prompt for NTP Servers
$ntpone = '10.73.66.100'
$ntptwo = '10.73.66.101'

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