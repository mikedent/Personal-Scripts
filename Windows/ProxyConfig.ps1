$ProxyServer = "webgate.rcc.org"
$ProxyPort     = "8080"
$Proxy = $ProxyServer + ":" + $ProxyPort
$reg = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
$ProxyStatus = Read-Host "1 to Enable, 0 to Disable"

$settings = Get-ItemProperty -Path $reg
$settings.ProxyServer
$settings.ProxyEnable

If
Set-ItemProperty -Path $reg -Name ProxyServer -Value $Proxy

Set-ItemProperty -Path $reg -Name ProxyEnable -Value 1

Set-ItemProperty -Path $reg -Name ProxyEnable -Value 0
Remove-ItemProperty -Path $reg -Name ProxyServer

