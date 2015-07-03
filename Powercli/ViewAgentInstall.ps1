param ( 
 
    [string]$vmSearchString = $(throw "VM REQUIRED"),
    [string]$viServer = "172.30.3.3",
    [string]$viUsername = "administrator@vsphere.local",
    [string]$viPassword = "G0lden*ak",
    [string]$desktopUsername="lmoplab\administrator",
    [string]$desktopPassword="admin",
    [string]$sourceAgentPath="\\192.168.129.2\Software\VMware\View\6.1\VMware-viewagent-x86_64-6.1.0-2509441", #I.E. \\fileserver\public\agent-5.2-123456.exe
    [string]$destinationAgentDir="c:\",
    [string]$agentLocalOptions="ALL",
    [string]$rebootDelay="120" #should be greater than 60 and higher if you have slow VM's or are going to process many upgrades at once
)
 
add-pssnapin VMware.VimAutomation.Core
 
connect-viserver -server $viServer -user $viUsername -password $viPassword
 
Function upgradeAgent($vmname){
 
    $fileName=$global:sourceAgentPath.split('\')[-1]
    $destinationFilePath="$($global:destinationAgentDir)" #$($fileName)
    $remoteExeFullPath = "$($global:destinationAgentDir)$($fileName)"
    $sourceAgentPath = $global:sourceAgentPath
    $desktopUsername = $global:desktopUsername
    $desktopPassword = $global:desktopPassword
    $agentLocalOptions = $global:agentLocalOptions
    $rebootDelay = $global:rebootDelay
 
    Write-Host "Updating $vmname..."
 
    Write-Host "Copying Files..."
    Write-Host "VM Name: $vmname"
    Write-Host "Source Agent Path: $sourceAgentPath"
    Write-Host "Destination Path: $destinationFilePath"
    Write-Host "Guest Desktop User: $desktopUsername"
    Write-Host "Guest Desktop Password: ($($desktopPassword.length) Characters)"
    Write-Host "Trying transfer..." -NoNewLine
 
    try {
        get-item $sourceAgentPath | copy-vmguestfile -destination $destinationFilePath -vm $vmname -guestuser $desktopUsername -guestpassword $desktopPassword -localtoguest
    } catch {
        Write-Host "Failed."
        throw $error
        return false;
    }
 
    Write-Host "Done."
 
    Write-Host "Making sure VMtools is running..." -NoNewLine
 
    Do{
        $status = Get-vm $vmname | %{ $_.guest |%{ $_.extensiondata.toolsrunningstatus } }
    } until ($status –eq  "guestToolsRunning")
 
    Write-Host "Done."
 
    #We need to make sure to really supress the reboot to give the USB driver time to install and initialize after the agent completes its installation
    $script='"'+$remoteExeFullPath+'" /s /v "/qn REBOOT=ReallySuppress ADDLOCAL='+$agentLocalOptions+'"'
    $script2="shutdown -r -t $rebootDelay"
 
    Write-Host "Executing Agent Upgrade..." -NoNewLine
    try {
        Invoke-VMScript -ScriptText $script –VM $vmname -guestuser $desktopUsername -guestpassword $desktopPassword -ScriptType Bat
    } 
    catch {
        Write-Host "Failed."
        throw $error[0]
        return false;
 
    }
 
    Write-Host "Done."
 
    Write-Host "Making sure VMtools is running again..." -NoNewLine
 
    Do{
        $status = Get-vm $vmname | %{ $_.guest |%{ $_.extensiondata.toolsrunningstatus } }
    } until ($status –eq  "guestToolsRunning")
 
    Write-Host "Done."
 
    Write-Host "Executing Reboot (Delay: $rebootDelay seconds)" -NoNewLine
    try {
        Invoke-VMScript -ScriptText $script2 –VM $vmname -guestuser $desktopUsername -guestpassword $desktopPassword -ScriptType Bat
    } 
    catch {
        Write-Host "Failed."
        throw $error[0]
         return false
    }
 
    Write-Host "Done."
 
    Write-Host "Finished upgrading Agent on $vmname."
 
}

$vms = get-VM -name $vmSearchString
 
if($vms -is [system.array] -and $vms.Count -gt 0){
 
    Write-Host "$($vms.Count) VMs found with the search string $vmSearchString we will try to upgrade them."
    foreach($vmObject in $vms){
 
        upgradeAgent $vmObject.Name
 
    }
 
}
elseif($vms.Name){
 
    Write-Host "1 VM found with search string $vmSearchString."
    upgradeAgent $vms.Name
 
}
else{
 
    Write-Host "NO VMs FOUND WITH SEARCH STRING $vmSearchString."
 
}