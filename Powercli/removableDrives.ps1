## removableDrives.ps1
##   This lists Virtual Machines which have connected removable media 
##   and prompts to disconnect all removable drives.
## Inputs
##   None
## Processing
##   Select VMs which have a CDROM or Floppy drive that is either connected or set to start connected
##   For each VM
##     Display all CDROM and Floppy drives and their current connection and power up state
##   Ask whether to disconnect any connected drives and turn off startup connected 
##   If requested,
##     Go through the same VM's and disconnect and turn off start connected for all
##       CDROM and Floppy drives
## 
## Revision History
## 2008-10-10 V1.0a Created

Get-Vm | Where-Object {
  (((Get-CDDrive -VM $_ | Where-Object { (($_.ConnectionState.Connected -eq $True) -or ($_.ConnectionState.StartConnected -eq $True))} ) -ne $Null) `
  -or `
  ((Get-FloppyDrive -VM $_ | Where-Object { (($_.ConnectionState.Connected -eq $True) -or ($_.ConnectionState.StartConnected -eq $True))} ) -ne $Null))
  } | %{
  "VM: " + $_.Name + " (" + $_.PowerState + ")"
  Get-CDDrive -VM $_ | ForEach-Object { "  " + $_.Name + " Connected=" + $_.ConnectionState.Connected + " ConnectAtPowerUp=" + $_.ConnectionState.StartConnected }
  Get-FloppyDrive -VM $_ | ForEach-Object { "  " + $_.Name + " Connected=" + $_.ConnectionState.Connected + " ConnectAtPowerUp=" + $_.ConnectionState.StartConnected }
  }
 
if ("Y" -eq (Read-Host `
    ("Do you want to disconnect all removable drives, and disable the connect `n" + `
     "  at startup?  If you don't see any VMs everything is OK and you should `n" + `
     "  select N here.  Type Y or N"))) {
  Get-Vm | Where-Object {
    (((Get-CDDrive -VM $_ | Where-Object { (($_.ConnectionState.Connected -eq $True) -or ($_.ConnectionState.StartConnected -eq $True))} ) -ne $Null) `
    -or `
    ((Get-FloppyDrive -VM $_ | Where-Object { (($_.ConnectionState.Connected -eq $True) -or ($_.ConnectionState.StartConnected -eq $True))} ) -ne $Null))
    } | %{
    "VM: " + $_.Name + " (" + $_.PowerState + ")"
    Get-CDDrive -VM $_ | ForEach-Object { Set-CDDRIVE -CD $_ -StartConnected $False -Connected $False -Confirm:$False | %{ "  Changed " + $_.Name} }
    Get-FloppyDrive -VM $_ | ForEach-Object { Set-FloppyDRIVE -Floppy $_ -StartConnected $False -Connected $False -Confirm:$False | %{ "  Changed " + $_.Name} }
  }
}

"removableDrives.ps1 finished."
