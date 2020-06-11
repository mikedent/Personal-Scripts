<#
Author:  Mike Dent
Version: 1.0
Version History:
Purpose:  Reset ESXi host root password
#>
# Define variables
$vCServer = "balt-cadvc-tp.baltcad.city"
$VCUser = "administrator@vsphere.local"
$VCUserPass = 'TTka-2eN!e3*'
$cluster = "TP"


# Connect to vCenter 
Connect-VIServer -Server $VCServer -User $VCUser -Password $VCUserPass

$NewCredential = Get-Credential -UserName "root" -Message "Enter an existing ESXi username (not vCenter), and what you want their password to be reset to."

$vmHosts = Get-Cluster $cluster | Get-VMhost

Foreach ($vmhost in $vmhosts) {
    $esxcli = get-esxcli -vmhost $vmhost -v2 #Gain access to ESXCLI on the host.
    $esxcliargs = $esxcli.system.account.set.CreateArgs() #Get Parameter list (Arguments)
    $esxcliargs.id = $NewCredential.UserName #Specify the user to reset
    $esxcliargs.password = $NewCredential.GetNetworkCredential().Password #Specify the new password
    $esxcliargs.passwordconfirmation = $NewCredential.GetNetworkCredential().Password
    Write-Host ("Resetting password for: " + $vmhost) #Debug line so admin can see what's happening.
    $esxcli.system.account.set.Invoke($esxcliargs) #Run command, if returns "true" it was successful.
}
Disconnect-VIServer * -Confirm:$false