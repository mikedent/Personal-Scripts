##########################################################
#
# Reference: MS Windows Guest IP Modification
# Script: PowerCLI IP&DNS Modification
#
# Date: 2015-04-21
#
# Version 1.0
#
##########################################################

Write-Host "Please enter the ESXi/Vcenter Host IP Address:" -ForegroundColor Yellow -NoNewline
$VMHost = Read-Host

Write-Host "Please enter the ESXi/Vcenter Username:" -ForegroundColor Yellow -NoNewline
$User = Read-Host

Write-Host "Please enter the ESXi/Vcenter Password:" -ForegroundColor Yellow -NoNewline
$Pass = Read-Host

Connect-VIServer -Server $VMHost -User $User -Password $Pass

do {
#Return list of VM's
Get-VM | select name

#Prompt for VM name
Write-Host "Please enter the VM Name that requires IP modification:" -ForegroundColor Yellow -NoNewline
$VM = Read-Host

Write-Host "The current VM Network Configuration:" -ForegroundColor Yellow
#Display Existing NIC Configuration
$shownet = "netsh interface ip show config"
Invoke-VMScript -ScriptText $shownet -VM $vm -GuestUser administrator -GuestPassword MSPassword -ScriptType Bat

################################
# Modify IP Configuration? y/n #
################################

Write-Host "Modify IP Details? " -ForegroundColor Yellow -NoNewline
Write-Host " Y/N:" -ForegroundColor Red -NoNewline
$IPChange = Read-Host

if ($IPChange -eq "y") {
Write-Host "Please provide the following IP details:" -ForegroundColor Yellow
#Prompt for IP Updates:
Write-Host "Interface Name:" -ForegroundColor Green -NoNewline
$NIC = Read-Host
Write-Host "New IP address:" -ForegroundColor Green -NoNewline
$IP = Read-Host
Write-Host "New Netmask:" -ForegroundColor Green -NoNewline
$NETMASK = Read-Host
Write-Host "New Gateway:" -ForegroundColor Green -NoNewline
$Gateway = Read-Host

#Invoke Windows netsh Script
$script = "netsh interface ip set address ""$NIC"" static $IP $NETMASK $Gateway"
Invoke-VMScript -ScriptText $script -VM $vm -GuestUser administrator -GuestPassword MSPassword -ScriptType Bat
}

#################################
# Modify DNS Configuration? y/n #
#################################
Write-Host "Modify DNS Details? " -ForegroundColor Yellow -NoNewline
Write-Host " Y/N:" -ForegroundColor Red -NoNewline
$DNSChange = Read-Host

if ($DNSChange -eq "y") {
#Prompt for Primary DNS IP:
Write-Host "Enter Primary DNS IP:" -ForegroundColor Green -NoNewline
$DNS1 = Read-Host
Write-Host "Enter Secondary DNS IP:" -ForegroundColor Green -NoNewline
$DNS2 = Read-Host

$DNSPrimary = "netsh interface ip set dnsservers name=""$NIC"" static $DNS1"
Invoke-VMScript -ScriptText $DNSPrimary -VM $vm -GuestUser administrator -GuestPassword MSPassword -ScriptType Bat

$DNSSecondary = "netsh interface ip add dnsservers name=""$NIC"" $DNS2 index=2"
Invoke-VMScript -ScriptText $DNSSecondary -VM $vm -GuestUser administrator -GuestPassword MSPassword -ScriptType Bat

}

# Display Network Configuration #
Invoke-VMScript -ScriptText $shownet -VM $vm -GuestUser administrator -GuestPassword MSPassword -ScriptType Bat

Write-Host "Change IP Configuration for another WINDOWS Guest VM? " -ForegroundColor Yellow -NoNewline
Write-Host " Y/N:" -ForegroundColor Red -NoNewline
$response = Read-Host
}
while ($response -eq "Y")
