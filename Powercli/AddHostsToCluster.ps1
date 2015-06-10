Connect-VIServer 10.10.92.41 -User administrator@vsphere.local -Password Pdntsp@7

$cluster = "CAD Cluster"
$user = "root"
$pass = "Pdntsp@7"

# Add to Cluster

Get-Content C:\hosts.txt | Foreach-Object { Add-VMHost $_ -Location (Get-Cluster $cluster) -User $user -Password $pass  -RunAsync -force:$true}
Disconnect-VIServer