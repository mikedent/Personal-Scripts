 $VMs = Get-View -ViewType VirtualMachine -Property name,guest,config.version,runtime.PowerState
    $report = @()
    $progress = 1
    foreach ($VM in $VMs) {
        Write-Progress -Activity "Checking vmware tools status" -Status "Working on $($VM.Name)" -PercentComplete ($progress/$VMs.count*100) -ErrorAction SilentlyContinue
        $object = New-Object PSObject
        Add-Member -InputObject $object NoteProperty VM $VM.Name
        if ($VM.runtime.powerstate -eq "PoweredOff") {Add-Member -InputObject $object NoteProperty ToolsStatus "$($VM.guest.ToolsStatus) (PoweredOff)"}
        else {Add-Member -InputObject $object NoteProperty ToolsStatus $VM.guest.ToolsStatus}
        Add-Member -InputObject $object NoteProperty ToolsVersionStatus ($VM.Guest.ToolsVersionStatus).Substring(10)
        Add-Member -InputObject $object NoteProperty SupportState ($VM.Guest.ToolsVersionStatus2).Substring(10)
        if ($object.ToolsStatus -eq "NotInstalled") {Add-Member -InputObject $object NoteProperty Version ""}
        else {Add-Member -InputObject $object NoteProperty Version $VM.Guest.ToolsVersion}
        Add-Member -InputObject $object NoteProperty "HW Version" $VM.config.version
        $report += $object
        $progress++
        }
    Write-Progress -Activity "Checking vmware tools" -Status "All done" -Completed -ErrorAction SilentlyContinue
 
    $report | Format-Table