Get-VM | Sort Name | Get-Snapshot | Where { $_.Name.Length -gt 0 } | Select VM,Name,Description,Created

$VMs = Get-VM -Location ( Get-Folder EMR5 )
foreach( $vm in $VMs ) { Set-VM -VM $vm -Snapshot ( Get-Snapshot -VM $vm -Name InititalConfig ) }

Get-Snapshot -VM "EMR*" -Name InititalConfig