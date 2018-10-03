Connect-VIServer 10.2.225.22 -User root -Password "Tr!t3cH1"
Get-VMhost | Get-AdvancedSetting -Name "ScratchConfig.ConfiguredScratchLocation" | Set-AdvancedSetting -Value "/vmfs/volumes/5b85b01b-e75f6586-2bf1-00fcba2e8556/.locker-EBRPRDVMHOST03"
Disconnect-VIServer -Server * -Confirm:$false