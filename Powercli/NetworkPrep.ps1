$viserver = "172.18.102.13"
#$cluster = "STA-Temp"
$vSwitch = "vSwitch0"
#$vSwitchPN = "Payment Network"
#$vSwitchDMZ = "DMZ"
$csvName = "/Users/mikedent/GitHub/Personal-Scripts/Powercli/PortGroups.csv" 

# Connect to vCenter 
Connect-VIServer -Server $viserver -User 'root' -Password 'rcco-cop06'
$vmhosts = Get-VMhost
#$vmhosts = Get-VMHost

Get-VirtualPortGroup -Name 'VM Network' | Remove-VirtualPortGroup -Confirm:$false
<# # Add vSwitch  to hosts
ForEach ($vmhost in $vmhosts) {
    New-VirtualSwitch -VMHost $vmhost -Name $vSwitchPN -NumPorts 64
    New-VirtualSwitch -VMHost $vmhost -Name $vSwitchDMZ -NumPorts 64 -nic vmnic3
} #>
# Add Port Groups to Host
$csv = Import-CSV $csvName
$VMHosts = Get-VMHost
Foreach ($pg in $csv) {
    $PGName = $pg.pgName
    $PGVlan = $pg.vlanId
    Foreach ($VMHost in $VMHosts) {
        IF (($VMHost | Get-VirtualPortGroup -name $PGName -ErrorAction SilentlyContinue) -eq $null) {
            Write-host "Creating $PGName on VMhost $VMHost" -ForegroundColor Yellow
            Get-VirtualSwitch -VMhost $vmhost -name $vSwitch | New-VirtualPortGroup -Name $pg.pgName -VLanId $pg.'vlanId ' 
        }
    }
}
Disconnect-VIServer -Server * -Confirm:$false