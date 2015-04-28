# ====================================================================================================================
#
# NAME: ESXi UCS Firmware Updates.ps1
#
# AUTHOR: Conor Casey
# DATE  : 03/06/2014
#
# COMMENT: Script to update UCS firmware levels on a UCS blade. Script syntex:-
#
#     UCSFirmwareUpdates -vCenterServer <> -Ucsm <> -vCenterCluster <> -HostFirmwarePolicy <> -UcsUser <> -UcsPass <> -FNICDriver <> -ENICDriver <> > <OutputLogfileLocation>
#
# ====================================================================================================================

## Required parameters
param
(
  [Parameter(Mandatory=$True, HelpMessage="vCenter Server to connect to")]
  [string]$vCenterServer,

  [Parameter(Mandatory=$True, HelpMessage="UCSM environment to connect to")]
  [string]$Ucsm,

  [Parameter(Mandatory=$True, HelpMessage="vCenter cluster to update")]
  [string]$vCenterCluster,

  [Parameter(Mandatory=$True, HelpMessage="Host Firmware Policy to apply")]
  [string]$HostFirmwarePolicy,

  [Parameter(Mandatory=$True, HelpMessage="UCSM Username")]
  [string]$UcsUser,

  [Parameter(Mandatory=$True, HelpMessage="UCSM Password")]
  [string]$UcsPass,

  [Parameter(Mandatory=$True, HelpMessage="FNIC Driver")]
  [string]$FNICDriver,

  [Parameter(Mandatory=$True, HelpMessage="ENIC Driver")]
  [string]$ENICDriver
)


## Add VMware Snapins
if ((Get-PSSnapin -Name VMware.VimAutomation.Core -ErrorAction SilentlyContinue) -eq $null )
{
    Add-PSSnapin VMware.VimAutomation.Core;
}
if ((Get-PSSnapin -Name VMware.VumAutomation -ErrorAction SilentlyContinue) -eq $null )
{
    Add-PSSnapin VMware.VumAutomation;
}

## Import UCS Module if not imported
if ((Get-Module |where {$_.Name -ilike "CiscoUcsPS"}).Name -ine "CiscoUcsPS")
{
	Import-Module CiscoUcsPs
}



## Put host in maintenance mode
Function MaintenanceMode([string]$Setting, [string]$ESXiHost)
{
    If ($Setting -eq "enter")
    {
        Write-Host "`nPutting host $ESXiHost in maintenace mode..."

        ## If host already in maintenance mode, leave in maintenance mode after remediation
        If ((Get-vmhost $ESXiHost).ConnectionState -eq "Maintenance")
        {
            Write-Host "Host $ESXiHost already in Maintenance Mode"
            Return 2
        }
        else
        {
            Set-VMHost -State Maintenance -VMHost $ESXiHost > $null
            If ((Get-vmhost $ESXiHost).ConnectionState -eq "Maintenance")
            {
                Write-Host "Host in maintenance mode"
                Return 5
            }
            else {"Host failed to enter maintenance mode. Remediate manually"; Return 10}
        }
    }
    ElseIf ($Setting -eq "exit")
    {
        ## Take host out of maintenance mode
        Write-Host ("Taking $ESXiHost out of maintenance mode...")
        Set-VMHost -State Connected -VMHost $ESXiHost > $null
        If ((Get-vmhost $ESXiHost).ConnectionState -eq "Connected")
        {
            Write-Host "Host out of maintenance mode"
        }
    }
}



Function UpdateFirmwareDriverLevels
{
    ## Connecting to vCenter
    Write-Host "Logging into vCenter Server: $vCenterServer"
    If (!(Connect-VIServer $vCenterServer)) {"Invalid vCenter Server. Exiting"; exit}

    ## Connect to UCSM
    #If (!(Connect-Ucs $Ucsm)) {"Invalid UCSM. Exiting"; Disconnect-VIServer $vCenterServer -confirm:$false; exit}

	Write-Host "Logging into UCS Domain: $Ucsm"
	$UcsPasswd = ConvertTo-SecureString $UcsPass -AsPlainText -Force
	$UcsCreds = New-Object System.Management.Automation.PSCredential ($UcsUser, $UcsPasswd)
	$UcsLogin = Connect-Ucs -Credential $UcsCreds $Ucsm

    ## Enter Cluster name and ensure DRS is enabled on that cluster
    If (!(Get-Cluster $vCenterCluster)) {"Invalid Cluster name. Exiting"; Disconnect-VIServer $vCenterServer -confirm:$false; Disconnect-Ucs; exit}
    ElseIf ((Get-Cluster $vCenterCluster).DrsEnabled -ne "True") {"DRS not enabled on this cluster. Will need to remediate manually. Exiting"; Disconnect-VIServer $vCenterServer -confirm:$false; exit}



    $HFPList = Get-UcsFirmwareComputeHostPack

    if ($HFPList.name.contains($HostFirmwarePolicy) -ine "true")
    {
        Write-Host "`nERROR! Not a valid Host Firmware Profile, exiting"
        Disconnect-Ucs
        Disconnect-VIServer -server $vCenterServer -confirm:$false
        exit
    }


    ## Unmount the cdrom device on any VMs in the cluster to avoid vmotion issues
    foreach ($VM in (Get-Cluster $vCenterCluster |Get-VM))
    {
        $VMCDInfo = $VM |Get-CDDrive

        if ($VMCDInfo.IsoPath -ine $null)
        {
           Write-Host "Unmounting CD/DVD drive media on $($VM.Name)"
           $VM |Get-CDDrive | Set-CDDrive -NoMedia -Confirm:$false
        }
    }


    Write-Host "`nUpdating UCS Firmware Levels : $(Get-Date -format "dd-MMM-yyyy HH:mm")"


    foreach ($ESXiHost in (Get-Cluster $vCenterCluster |Get-VMHost))
    {
        Write-Host "`n`n####### Starting UCS firmware and driver update work on $ESXiHost : $(Get-Date -format "dd-MMM-yyyy HH:mm") #######"

        Write-Host "Updating ENIC and FNIC Drivers"

        ## Grab esxcli data for ESXi Host
        $esxcli = Get-EsxCli -VMHost $ESXiHost
        $esxcli.software.vib.update($ENICDriver)
        $esxcli.software.vib.update($FNICDriver)
        Sleep 10

        Write-Host "Driver updates complete, moving on to firmware updates"

        ## Match VM Host name to UCS service profile
        $vmhostMacAddr = (Get-VMHostNetworkAdapter -VMHost $ESXiHost |where {$_.Name -ieq "vmnic0"}).Mac
        #$UCSserviceprofileInfo = Get-UcsServiceProfile |Get-UcsVnic -Name mgmt-A | where {$_.addr -ieq "$vmhostMacAddr"} | get-UCSParent
        $UCSserviceprofileInfo = Get-UcsServiceProfile |Get-UcsVnic -Name 0 | where {$_.addr -ieq "$vmhostMacAddr"} | get-UCSParent
        Write-Host "ESXi Host $ESXiHost belongs to UCS profile $($UCSserviceprofileInfo.name)"
        Write-Host "Current Host Firmware Policy associated with $($UCSserviceprofileInfo.name) is $((Get-UcsServiceProfile -Name $($UCSserviceprofileInfo.name)).HostFwPolicyName). Updating to $HostFirmwarePolicy"

        ## Check if profile is already at correct host firmware policy level. If it is then skip it
        if (((Get-UcsServiceProfile -Name $($UCSserviceprofileInfo.name)).HostFwPolicyName) -eq $HostFirmwarePolicy)
        {
            Write-Host "Host $($UCSserviceprofileInfo.name) is already on Host Firmware Policy $HostFirmwarePolicy, skipping this host"
        }
        Else
        {
            $MMCheck = MaintenanceMode "enter" $ESXiHost
            If ($MMCheck -eq 5 -or $MMCheck -eq 2)
            {
                ## Shut down the host
                Write-Host "Gracefully shutting down $ESXiHost..."
                $ESXiHost.ExtensionData.ShutdownHost($true)
                do {
		            Sleep 20
                } until ((Get-UcsManagedObject -dn $UCSServiceProfileInfo.PnDn).OperPower -ieq "off" -and (Get-vmhost $ESXiHost).ConnectionState -ieq "NotResponding")
                Write-Host "Host $($UCSserviceprofileInfo.name) powered down"

                ## Attach Host Firmware Policy to UCS Service Profile
                Write-Host "Applying Host Firmware Policy..."
                $UCSserviceprofileInfo | Set-UcsServiceProfile -HostFwPolicyName $HostFirmwarePolicy -Force > $null
                $UCSserviceprofileInfo | Get-UcsLsmaintAck | Set-UcsLsmaintAck -AdminState "trigger-immediate" -Force > $null

                ## After update is complete, make sure host is connected back to vCenter before starting ESXi update
                do {
                    sleep 20
                } until (((Get-vmhost $ESXiHost).ConnectionState -ieq "Connected") -or ((Get-vmhost $ESXiHost).ConnectionState -ieq "Maintenance"))

                If ((Get-UcsServiceProfile -Name $($UCSserviceprofileInfo.name)).HostFwPolicyName -ieq $HostFirmwarePolicy) {"Firmware update on $($UCSserviceprofileInfo.name) complete"}
                Else {"Firmware update on $($UCSserviceprofileInfo.name) did not complete successfully, current version is $((Get-UcsServiceProfile -Name $($UCSserviceprofileInfo.name)).HostFwPolicyName)"}

                If ($MMCheck -eq 5) {MaintenanceMode "exit" $ESXiHost}

                ## Set the vmkcore partition in case it got disabled following the reboot
                Write-Host "Ensure vmkcore partition is enabled following reboot..."
                $esxcli.system.coredump.partition.set($true)

                Write-Host "UCS firmware and driver update work on $ESXiHost complete : $(Get-Date -format "dd-MMM-yyyy HH:mm")"
            }
        }
    }

Write-Host "`nUCS firmware update work complete : $(Get-Date -format "dd-MMM-yyyy HH:mm")"

Disconnect-VIServer $vCenterServer -confirm:$false
Disconnect-Ucs
}



################################# Start Program Execution ###################################

## Make sure there are no old connections to UCS lingering. This can cause issues within the script
Disconnect-Ucs

UpdateFirmwareDriverLevels
