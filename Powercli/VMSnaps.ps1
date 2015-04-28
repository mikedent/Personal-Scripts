# Powershell for Snapshotting VM's
# Variable for VM Name capture
$powerOption = Read-Host "Do you want to start or stop VM's? (Press 1 for Stop and 2 for Start)"
$vm = "EMRAPP"
#$vmPowerOff = (Get-VM $vm | stop-vm)
#New-Snapshot -VM (Get-VM $vm) -Name InititalConfig
#$vmPowerOn = (Get-VM $vm | Start-VM)

switch ($powerOption)
	{
		1 {Get-VM $vm | stop-vm}
		2 {Get-VM $vm | Start-VM}
	}	