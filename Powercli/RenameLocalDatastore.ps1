# Variables
$vCenter = '10.111.114.59'
$vCUser = 'root'
$vCPassword = 'LBUl)EV^ma+82TK'
$cluster = 'MGMT'
$suffix = '-local-ds'

# Connect to vCenter
Connect-VIServer -Server $vCenter -User $vCUser -Password $vCPassword

# Rename local datastores
#get-cluster $cluster | 
get-vmhost | % {
    $_ | get-datastore | ? { $_.name -match "^datastore1( \(\d+\))?$" } | set-datastore -name "$($_.name.split(".")[0])$suffix"
}

