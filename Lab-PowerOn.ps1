#PowerShell filter to add date/timestamps
filter timestamp {"$(Get-Date -Format G): $_"}

# Powering on all hosts via IPMI
# Assumes that networking is online
# Assumes that LABDC01 (physical) and both Synology NAS's are online
ipmitool -I lanplus -H 10.10.205.5 -U admin -P "admin" power on
ipmitool -I lanplus -H 10.10.205.10 -U ADMIN -P "ADMIN" power on
ipmitool -I lanplus -H 10.10.205.15 -U ADMIN -P "ADMIN" power on
ipmitool -I lanplus -H 10.10.205.20 -U ADMIN -P "ADMIN" power on
ipmitool -I lanplus -H 10.10.205.25 -U ADMIN -P "ADMIN" power on
ipmitool -I lanplus -H 10.10.205.30 -U ADMIN -P "ADMIN" power on
ipmitool -I lanplus -H 10.10.205.100 -U ADMIN -P "ADMIN" power on
ipmitool -I lanplus -H 10.10.205.105 -U ADMIN -P "ADMIN" power on
ipmitool -I lanplus -H 10.10.205.110 -U ADMIN -P "ADMIN" power on

# Wait 30 seconds for hosts to come online
Start-Sleep -Seconds 30 |timestamp

# Check Connections to Management hosts
$computers = ("10.10.200.10","10.10.200.15")
foreach ($computer in $computers)
{
    if(test-connection -computername $computers -quiet)
    "Host is online"|timestamp
}
else {
    Start-Sleep -Seconds 10
}
# Test connection to LABESXIM01
"Checking if LABESXIM01 is online  ..."|timestamp
do {
    "Waiting for host to come online"|timestamp
    $checkHost = Test-Connection -Computername 10.10.200.10 -Quiet
    "Host isn't online, waiting for 10 seconds"|timestamp
    Start-Sleep -Seconds 10
} until($checkHost -eq $true)
"Host is online"|timestamp

# Test connection to LABESXIM02
"Checking if LABESXIM02 is online  ..."|timestamp
if (Test-Connection -computername 10.10.200.15 -Quiet) {
    "Host is online"|timestamp
}
else {
    "Host is not online, sleeping for 10 seconds" | timestamp
    Start-Sleep -Seconds 10
}


do {
    "Waiting for host to come online"|timestamp
    $checkHost = Test-Connection -Computername 10.10.200.15 -Quiet
    Start-Sleep -Seconds 10
} until($checkHost -eq $true)
"Host is online"|timestamp

# Check for Existence of vCenter and power on
"Connecting to LABESXM01 ..."|timestamp
Connect-VIServer -Server 10.10.200.10 -User root -Password "G0lden*ak"
$VCSA = get-vm -name "LABVCENTER" -ErrorAction SilentlyContinue  
If ($VCSA) {  
    "LABVCENTER will now be powered on" | timestamp
    Start-VM $VCSA
    "Disconnecting from LABESXM01 ..."|timestamp
    Disconnect-VIServer -Server * -Force -Confirm:$false
}  
Else {  
    "LABVCENTER not found, moving onto LABESXIM02" | timestamp
    "Disconnecting from LABESXM01 ..."|timestamp
    Disconnect-VIServer -Server * -Force -Confirm:$false
    Connect-VIServer -Server 10.10.200.15 -User root -Password "G0lden*ak"
    If ($VCSA) {  
        "LABVCENTER will now be powered on" | timestamp
        Start-VM $VCSA
        "Disconnecting from LABESXM01 ..."|timestamp
        Disconnect-VIServer -Server * -Force -Confirm:$false
    }  
    Else {  
    "LABVCENTER not found" | timestamp
    "Disconnecting from LABESXM02 ..."|timestamp
    Disconnect-VIServer -Server * -Force -Confirm:$false
    }
}  
