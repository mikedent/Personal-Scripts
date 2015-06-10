$vm = "AN*"
Get-VM $vm | select name, @{ Name = "IPAddress"; Expression = { $_.Guest.IPAddress }}