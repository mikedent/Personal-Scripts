# DHCPScopeCreation.ps1
# Script by Tim Buntrock
# This script will create a DHCP scope based on your input
# You can verify the config after you add all values, and if you confirm with "y," the scope will be created!
# You can add values like DNS server, Boot options, and so on to this script, but I set options like this using Server Options.
  
########### Script--->START ########### 
# Input Box
[void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic')
 $dhcpserver = [Microsoft.VisualBasic.Interaction]::InputBox("Enter DHCP server name", "DHCP server name", "$env:computername")
$scopename = [Microsoft.VisualBasic.Interaction]::InputBox("Enter Scope name", "Scope name", "")
$scopeID = [Microsoft.VisualBasic.Interaction]::InputBox("Enter Scope ID like 10.1.1.0", "Scope ID", "10.")
$startrange = [Microsoft.VisualBasic.Interaction]::InputBox("Enter Start IP", "Start IP", "10.")
$endrange = [Microsoft.VisualBasic.Interaction]::InputBox("Enter End IP", "End IP", "10.")
$subnetmask = [Microsoft.VisualBasic.Interaction]::InputBox("Enter Subnetmask", "Subnetmask", "255.255.255.0")
$router = [Microsoft.VisualBasic.Interaction]::InputBox("Enter Router IP", "Router IP", "10.")
Write-Host
Write-Host ----------Preconfigured Settings----------- -foregroundcolor "yellow"
Write-Host
Write-Host Server: {}{}{}{}{}{}{}{} $dhcpserver -foregroundcolor "yellow"
Write-Host Scope Name: {}{}{}{} $scopename -foregroundcolor "yellow"
Write-Host Scope ID: {}{}{}{}{}{} $scopeID -foregroundcolor "yellow"
Write-Host IP Range: {}{}{}{}{}{} $startrange - $endrange -foregroundcolor "yellow"
Write-Host Subnetmask: {}{}{}{} $subnetmask -foregroundcolor "yellow"
Write-Host Router: {}{}{}{}{}{}{}{} $router -foregroundcolor "yellow"
Write-Host
Write-Host ---------/Preconfigured Settings----------- -foregroundcolor "yellow"
Write-Host
Write-Host
Write-Host
Write-Host Type in y to continue or any key to cancel...
Write-Host
$input = [Microsoft.VisualBasic.Interaction]::InputBox("Type in y to continue `n or any key to cancel...", "Create Scope", "")
if(($input) -eq "y" )
{    
     Add-DHCPServerv4Scope -ComputerName $dhcpserver -EndRange $endrange -Name $scopename -StartRange $startrange -SubnetMask $subnetmask -State Active
     Set-DHCPServerv4OptionValue -ComputerName $dhcpserver -ScopeId $scopeID -Router $router
 
     Write-Host
     Write-Host
     Write-Host Created Scope $scopename  on Server $dhcpserver -foregroundcolor "green"
     Write-Host
     Write-Host ---------------Settings-------------------- -foregroundcolor "green"
     Write-Host ------------------------------------------- -foregroundcolor "green"
     Write-Host
     Write-Host Scope Name: {}{}{} $scopename -foregroundcolor "green"
     Write-Host Scope ID: {}{}{}{}{} $scopeID -foregroundcolor "green"
     Write-Host IP Range: {}{}{}{}{} $startrange - $endrange -foregroundcolor "green"
     Write-Host Subnetmask: {}{}{} $subnetmask -foregroundcolor "green"
     Write-Host Router: {}{}{}{}{}{}{} $router -foregroundcolor "green"
     Write-Host
     Write-Host ------------------------------------------- -foregroundcolor "green"
     Write-Host --------------/Settings-------------------- -foregroundcolor "green"
}
else 
{
     exit
}