# Set CD/DVD Drive to Z:
$cd = $NULL
$cd = Get-WMIObject -Class Win32_CDROMDrive -ComputerName $env:COMPUTERNAME -ErrorAction Stop
if ($cd.Drive -eq "D:")
{
   Write-Output "Changing CD Drive letter from D: to Z:"
   Set-WmiInstance -InputObject ( Get-WmiObject -Class Win32_volume -Filter "DriveLetter = 'd:'" ) -Arguments @{DriveLetter='z:'}
}