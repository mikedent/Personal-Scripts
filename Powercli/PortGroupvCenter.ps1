$NetworkInfo = Import-CSV Port-Groups.csv
$ClusterName = "Conway"
$VMHosts = Get-Cluster $ClusterName | Get-VMHost
$vSwitch = "vSwitch0"
Foreach ($network in $NetworkInfo){
    $PortGroup = $network.PortGroup
    $VLANID = $Network.VLANID
    Foreach ($VMHost in $VMHosts){
        IF (($VMHost | Get-VirtualPortGroup -name $PortGroup -ErrorAction SilentlyContinue) -eq $null){
            Write-host "Creating $PortGroup on VMhost $VMHost" -ForegroundColor Yellow
            $NEWPortGroup = $VMhost | Get-VirtualSwitch -Name $vSwitch | New-VirtualPortGroup -Name $PortGroup -VLanId $VLANID
        }
    }
}
