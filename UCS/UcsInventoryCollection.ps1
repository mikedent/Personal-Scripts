<#
UcsInventoryCollection.ps1 Version=1.0

Execution string:  .\UcsInventoryCollection.ps1 -ucsm "<host1,host2,..>" -credential  <psCredential> 
                   
Example:

$user = "<userName>"
$password = "<password>" | ConvertTo-SecureString -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential($user,$password)
.\UcsInventoryCollection.ps1 -ucsm "<host1>,<host2>" -credential $cred 

This script generates UCS inventory report for given UCS(s) .


#>

param(
  
  [parameter(Mandatory=${true})]
  [ValidateNotNullOrEmpty()]
  [string]${ucsm},

  [parameter(Mandatory=${true})]
  [System.Management.Automation.PSCredential]${credential},

  [INT]${show},

  [switch]${summ},
  
  [switch]${verb}
)

Write-Host ""  # must stay
#Write-Host "ucsd = $ucsm"
#Write-Host "show = $show"
#Write-Host "summ = $summ"
#Write-Host "verb = $verb"
#Write-Host "" # can go

if (($ucsm -eq "") -or ($show -lt 0) -or ($show -gt 5)) {
  Write-Host "usage: UcsInventory.ps1 -ucs host1[,host2[,host3...]] -show (0..5) [-sum] [-v]"
  Write-Host "       -ucsm        - a list of one or more hostnames or IP addresses"
  Write-Host "       -credential  - a list of one or more hostnames or IP addresses"
  Write-Host "       -show        - the level of detail to show"
  Write-Host "                      0 = default, show all except dimms"
  Write-Host "                      1 = only fab-int, chassis, blade, rackmount"
  Write-Host "                      2 = add cpu's and memory"
  Write-Host "                      3 = also hard drives and adapters"
  Write-Host "                      4 = plus psu's and fans"
  Write-Host "                      5 = show all dimms"
  Write-Host "       -sum         - summarize multiple identical items"
  Write-Host "       -v           - verbose output"
  Write-Host ""
  exit
}

# Constants
$hAlignLeft = -4131
$hAlignCenter = -4108
$hAlignRight = -4152

# Script shouldn't be run from C:\ because can't create spreadsheet there
if ($PSScriptRoot -eq "C:\") {
  Write-Host "Move script from 'C:\' to a folder like 'C:\Program Files\...' or 'C:\Users\You'"
  Write-Host "Exiting..."
  Write-Host ""
  exit
}

# When necessary create C:\Temp
if (-not (Test-Path "C:\Temp")) {
  mkdir "C:\Temp" > $null
  Write-Host "Directory C:\Temp created"
  Write-Host ""
}

# Create Part2Model Table

function Add-ModelRow ([array]$arr, [string]$PartNr, [string]$Model, [string]$Tag) {

  $rec = "" | Select "PartNr","Model","Tag"

  $rec.PartNr = $PartNr
  $rec.Model = $Model
  $rec.Tag = $Tag

  $arr += $rec
  $rec = $null

  return $arr
}

function Create-ModelTable {

  $csvFile = "C:\Temp\Part2Model.csv"
  if (Test-Path $($csvFile)) {
    del $csvFile -ErrorAction SilentlyContinue
  }

  $arr = @()
  $arr = Add-ModelRow -arr $arr -PartNr "N5K-C5010P-BF" -Model "FI6120"
  $arr = Add-ModelRow -arr $arr -PartNr "N5K-C5020P-BF" -Model "FI6140"
  $arr = Add-ModelRow -arr $arr -PartNr "N10-S6100" -Model "FI6120"
  $arr = Add-ModelRow -arr $arr -PartNr "N10-S6200" -Model "FI6140"
  $arr = Add-ModelRow -arr $arr -PartNr "N10-E0060" -Model "E0060"
  $arr = Add-ModelRow -arr $arr -PartNr "N10-E0080" -Model "E0080"
  $arr = Add-ModelRow -arr $arr -PartNr "N10-E0440" -Model "E0440"
  $arr = Add-ModelRow -arr $arr -PartNr "N10-E0600" -Model "E0600"
  $arr = Add-ModelRow -arr $arr -PartNr "UCS-FI-6248UP" -Model "FI6248UP"
  $arr = Add-ModelRow -arr $arr -PartNr "UCS-FI-6296UP" -Model "FI6296UP"
  $arr = Add-ModelRow -arr $arr -PartNr "UCS-FI-E16UP" -Model "E16UP"
  $arr = Add-ModelRow -arr $arr -PartNr "UCS-FI-M-6324" -Model "FI6324"
  $arr = Add-ModelRow -arr $arr -PartNr "N20-C6508" -Model "UCS5108"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSB-5108-AC2" -Model "UCS5108"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSB-5108-DC2" -Model "UCS5108"
  $arr = Add-ModelRow -arr $arr -PartNr "N20-I6584" -Model "IOM2104"
  $arr = Add-ModelRow -arr $arr -PartNr "UCS-IOM-2204XP" -Model "IOM2204"
  $arr = Add-ModelRow -arr $arr -PartNr "UCS-IOM-2208XP" -Model "IOM2208"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSB-B22-M3" -Model "B22-M3" -Tag "Silvercreek"
  $arr = Add-ModelRow -arr $arr -PartNr "N20-B6620-1" -Model "B200-M1" -Tag "Gooding"
  $arr = Add-ModelRow -arr $arr -PartNr "N20-B6625-1" -Model "B200-M2" -Tag "GoodingWestmere"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSB-B200-M3" -Model "B200-M3" -Tag "Castlerock"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSB-B200-M4" -Model "B200-M4" -Tag "Candlestick"
  $arr = Add-ModelRow -arr $arr -PartNr "N20-B6730-1" -Model "B230-M1" -Tag "Marin"
  $arr = Add-ModelRow -arr $arr -PartNr "B230-BASE-M2" -Model "B230-M2" -Tag "MarinWestmere"
  $arr = Add-ModelRow -arr $arr -PartNr "N20-B6620-2" -Model "B250-M1" -Tag "Ventura"
  $arr = Add-ModelRow -arr $arr -PartNr "N20-B6625-2" -Model "B250-M2" -Tag "VenturaWestmere"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSB-EX-M4-1C" -Model "B260-M4" -Tag "Yosemite"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSB-B420-M3" -Model "B420-M3" -Tag "Sequoia"
  $arr = Add-ModelRow -arr $arr -PartNr "N20-B6740-2" -Model "B440-M1" -Tag "SanFrancisco"
  $arr = Add-ModelRow -arr $arr -PartNr "B440-BASE-M2" -Model "B440-M2" -Tag "SanFranciscoWestmere"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSB-EX-M4-1A" -Model "B460-M4" -Tag "Yosemite"
  $arr = Add-ModelRow -arr $arr -PartNr "N20-AI0002" -Model "82598KR-CI"
  $arr = Add-ModelRow -arr $arr -PartNr "N20-AI0102" -Model "M61KR-I"
  $arr = Add-ModelRow -arr $arr -PartNr "N20-AE0002" -Model "M71KR-E"
  $arr = Add-ModelRow -arr $arr -PartNr "N20-AQ0002" -Model "M71KR-Q"
  $arr = Add-ModelRow -arr $arr -PartNr "N20-AC0002" -Model "M81KR"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSB-MEZ-BRC-02" -Model "M61KR-B"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSB-MEZ-ELX-03" -Model "M73KR-E"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSB-MEZ-QLG-03" -Model "M73KR-Q"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSB-MLOM-40G-01" -Model "VIC1240"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSB-MLOM-PT-01" -Model "EXP1240"
  $arr = Add-ModelRow -arr $arr -PartNr "UCS-VIC-M82-8P" -Model "VIC1280"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSB-MLOM-40G-03" -Model "VIC1340"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSB-VIC-M83-8P" -Model "VIC1380"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSB-F-FIO-365M" -Model "FIO-365M"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSB-F-FIO-785M" -Model "FIO-785M"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSB-F-FIO-1300MP" -Model "FIO-1300MP"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSB-F-FIO-1600MS" -Model "FIO-1600MS"
  $arr = Add-ModelRow -arr $arr -PartNr "N2K-C2148TP-1GE" -Model "C2148TP"
  $arr = Add-ModelRow -arr $arr -PartNr "N2K-C2248TP-1GE" -Model "C2248TP"
  $arr = Add-ModelRow -arr $arr -PartNr "N2K-C2224TP-1GE" -Model "C2224TP"
  $arr = Add-ModelRow -arr $arr -PartNr "N2K-C2232PP-10GE" -Model "C2232PP"
  $arr = Add-ModelRow -arr $arr -PartNr "N2K-C2232TM-10GE" -Model "C2232TM"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSC-C22-M3S" -Model "C22-M3" -Tag "Alameda1"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSC-C22-M3L" -Model "C22-M3" -Tag "Alameda1"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSC-C24-M3S" -Model "C24-M3" -Tag "Alameda2"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSC-C24-M3L" -Model "C24-M3" -Tag "Alameda2"
  $arr = Add-ModelRow -arr $arr -PartNr "R200-1120402" -Model "C200-M1" -Tag "SanDiego"
  $arr = Add-ModelRow -arr $arr -PartNr "R200-1120402W" -Model "C200-M2" -Tag "SanDiego"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSC-BSE-SFF-C200" -Model "C200-M2" -Tag "SanDiego"
  $arr = Add-ModelRow -arr $arr -PartNr "R210-2121605" -Model "C210-M1" -Tag "SanDiego"
  $arr = Add-ModelRow -arr $arr -PartNr "R210-2121605W" -Model "C210-M2" -Tag "SanDiego"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSC-C220-M3S" -Model "C220-M3" -Tag "SanLuis1"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSC-C220-M3L" -Model "C220-M3" -Tag "SanLuis1"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSC-C220-M4S" -Model "C220-M4" -Tag "DelNorte1"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSC-C220-M4L" -Model "C220-M4" -Tag "DelNorte1"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSC-C240-M3S" -Model "C240-M3" -Tag "SanLuis2"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSC-C240-M3L" -Model "C240-M3" -Tag "SanLuis2"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSC-C240-M4S" -Model "C240-M4" -Tag "DelNorte2"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSC-C240-M4S2" -Model "C240-M4" -Tag "DelNorte2"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSC-C240-M4SX" -Model "C240-M4" -Tag "DelNorte2"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSC-C240-M4L" -Model "C240-M4" -Tag "DelNorte2"
  $arr = Add-ModelRow -arr $arr -PartNr "R250-2480805" -Model "C250-M1" -Tag "LosAngeles"
  $arr = Add-ModelRow -arr $arr -PartNr "R250-2480805W" -Model "C250-M2" -Tag "LosAngeles"
  $arr = Add-ModelRow -arr $arr -PartNr "C260-BASE-2646" -Model "C260-M2" -Tag "SanMateo"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSC-C420-M3" -Model "C420-M3" -Tag "Amador"
  $arr = Add-ModelRow -arr $arr -PartNr "R460-4640810" -Model "C460-M1" -Tag "Alpine"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSC-BASE-M2-C460" -Model "C460-M2" -Tag "Alpine"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSC-C460-M4" -Model "C460-M4" -Tag "Imperial"
  $arr = Add-ModelRow -arr $arr -PartNr "C880-2T-HANA-M4" -Model "C880-M4"
  $arr = Add-ModelRow -arr $arr -PartNr "C880-2T-HANA-J-M4" -Model "C880-M4"
  $arr = Add-ModelRow -arr $arr -PartNr "C880-6T-HANA-M4" -Model "C880-M4"
  $arr = Add-ModelRow -arr $arr -PartNr "C880-6T-HANA-J-M4" -Model "C880"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSC-C3160" -Model "C3160"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSC-C3260" -Model "C3260"
  $arr = Add-ModelRow -arr $arr -PartNr "N2XX-ACPCI01" -Model "P81E" -Tag "Palo"
  $arr = Add-ModelRow -arr $arr -PartNr "N2XX-ABPCI01" -Model "BCM-5709" -Tag "Broadcom"
  $arr = Add-ModelRow -arr $arr -PartNr "N2XX-ABPCI02" -Model "BCM-57711" -Tag "Broadcom"
  $arr = Add-ModelRow -arr $arr -PartNr "N2XX-ABPCI03" -Model "BCM-5709" -Tag "Broadcom"
  $arr = Add-ModelRow -arr $arr -PartNr "N2XX-AEPCI01" -Model "EMX-10102-CNA" -Tag "Emulex"
  $arr = Add-ModelRow -arr $arr -PartNr "N2XX-AEPCI03" -Model "EMX-11002-HBA" -Tag "Emulex"
  $arr = Add-ModelRow -arr $arr -PartNr "N2XX-AEPCI05" -Model "EMX-12002-HBA" -Tag "Emulex"
  $arr = Add-ModelRow -arr $arr -PartNr "N2XX-AIPCI01" -Model "INT-X520" -Tag "Intel"
  $arr = Add-ModelRow -arr $arr -PartNr "N2XX-AIPCI02" -Model "INT-E1G44ETG1P20" -Tag "Intel"
  $arr = Add-ModelRow -arr $arr -PartNr "N2XX-AMPCI01" -Model "MLX-CX-2-SFP"
  $arr = Add-ModelRow -arr $arr -PartNr "N2XX-AQPCI01" -Model "QLC-8152-CNA" -Tag "QLogic"
  $arr = Add-ModelRow -arr $arr -PartNr "N2XX-AQPCI03" -Model "QLC-2462-HBA" -Tag "QLogic"
  $arr = Add-ModelRow -arr $arr -PartNr "N2XX-AQPCI05" -Model "QLC-2562-HBA" -Tag "QLogic"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSC-PCIE-CSC-02" -Model "VIC1225" -Tag "Lexington"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSC-PCIE-C10T-02" -Model "VIC1225T" -Tag "Lexington"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSC-MLOM-CSC-02" -Model "VIC1227" -Tag "Susanville"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSC-PCIE-C40Q-02" -Model "VIC1285" 
  $arr = Add-ModelRow -arr $arr -PartNr "UCSC-PCIE-BSFP" -Model "BCM-57712-SFP" -Tag "Broadcom"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSC-PCIE-BTG" -Model "BCM-57712-10T" -Tag "Broadcom"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSC-PCIE-B3SFP" -Model "BCM-57810-SFP" -Tag "Broadcom"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSC-PCIE-E14102" -Model "EMX-14102-CNA" -Tag "Emulex"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSC-PCIE-E16002" -Model "EMX-16002-HBA" -Tag "Emulex"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSC-PCIE-ESFP" -Model "EMX-11102-CNA" -Tag "Emulex"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSC-PCIE-IRJ45" -Model "INT-QUAD-GBE"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSC-PCIE-ITG" -Model "INT-X540-10T"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSC-PCIE-Q2672" -Model "QLC-2672-HBA"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSC-PCIE-Q8362" -Model "QLC-8362-CNA"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSC-F-FIO-365M" -Model "FIO-365M"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSC-F-FIO-785M" -Model "FIO-785M"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSC-F-FIO-1000MP" -Model "FIO-1000MP"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSC-F-FIO-1000PS" -Model "FIO-1000PS"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSC-F-FIO-1205M" -Model "FIO-1205M"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSC-F-FIO-1300MP" -Model "FIO-1300MP"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSC-F-FIO-1300PS" -Model "FIO-1300PS"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSC-F-FIO-2600MP" -Model "FIO-2600MP"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSC-F-FIO-2600PS" -Model "FIO-2600PS"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSC-F-FIO-3000M" -Model "FIO-3000M"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSC-F-FIO-5200MP" -Model "FIO-5200MP"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSC-F-FIO-5200PS" -Model "FIO-5200PS"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSC-GPU-VGXK1" -Model "VGX-K1"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSC-GPU-VGXK2" -Model "VGX-K2"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSC-GPU-K10" -Model "TESLA-K10"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSC-GPU-K20" -Model "TESLA-K20"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSC-GPU-K20X" -Model "TESLA-K20X"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSC-GPU-K40" -Model "TESLA-K40"

  $arr | Export-Csv "C:\Temp\Part2Model.csv"
  $arr = $null
}

function Add-PartNrRow ([array]$arr, [string]$Model, [string]$PartNr) {

  $rec = "" | Select "Model", "PartNr"

  $rec.Model = $Model
  $rec.PartNr = $PartNr

  $arr += $rec
  $rec = $null

  return $arr
}

function Create-OldCpuTable {

  $csvFile = "C:\Temp\Cpu2PartNr.csv"
  if (Test-Path $($csvFile)) {
    del $csvFile -ErrorAction SilentlyContinue
  }

  $arr = @()
  $arr = Add-PartNrRow -arr $arr -Model "E5504" -PartNr "N20-X00009"
  $arr = Add-PartNrRow -arr $arr -Model "E5506" -PartNr "A01-X0113"
  $arr = Add-PartNrRow -arr $arr -Model "E5520" -PartNr "N20-X00003"
  $arr = Add-PartNrRow -arr $arr -Model "E5520" -PartNr "N20-X00004"
  $arr = Add-PartNrRow -arr $arr -Model "L5520" -PartNr "N20-X00004"
  $arr = Add-PartNrRow -arr $arr -Model "L5520" -PartNr "N20-X00004"
  $arr = Add-PartNrRow -arr $arr -Model "E5540" -PartNr "N20-X00002"
  $arr = Add-PartNrRow -arr $arr -Model "X5550" -PartNr "N20-X00006"
  $arr = Add-PartNrRow -arr $arr -Model "X5570" -PartNr "N20-X00001"
  $arr = Add-PartNrRow -arr $arr -Model "E5606" -PartNr "A01-X0123"
  $arr = Add-PartNrRow -arr $arr -Model "L5609" -PartNr "A01-X0108"
  $arr = Add-PartNrRow -arr $arr -Model "E5620" -PartNr "A01-X0111"
  $arr = Add-PartNrRow -arr $arr -Model "L5630" -PartNr "A01-X0107"
  $arr = Add-PartNrRow -arr $arr -Model "E5640" -PartNr "A01-X0109"
  $arr = Add-PartNrRow -arr $arr -Model "L5640" -PartNr "A01-X0106"
  $arr = Add-PartNrRow -arr $arr -Model "E5645" -PartNr "UCS-CPU-E5645"
  $arr = Add-PartNrRow -arr $arr -Model "E5649" -PartNr "A01-X0120"
  $arr = Add-PartNrRow -arr $arr -Model "X5650" -PartNr "A01-X0105"
  $arr = Add-PartNrRow -arr $arr -Model "X5660" -PartNr "UCS-CPU-X5660"
  $arr = Add-PartNrRow -arr $arr -Model "X5670" -PartNr "A01-X0102"
  $arr = Add-PartNrRow -arr $arr -Model "X5675" -PartNr "A01-X0117"
  $arr = Add-PartNrRow -arr $arr -Model "X5680" -PartNr "A01-X0100"
  $arr = Add-PartNrRow -arr $arr -Model "X5687" -PartNr "UCS-CPU-X5687"
  $arr = Add-PartNrRow -arr $arr -Model "X5690" -PartNr "A01-X0115"
  $arr = Add-PartNrRow -arr $arr -Model "E6510" -PartNr "A01-X0302"
  $arr = Add-PartNrRow -arr $arr -Model "E6540" -PartNr "A01-X0304"
  $arr = Add-PartNrRow -arr $arr -Model "X6550" -PartNr "A01-X0308"
  $arr = Add-PartNrRow -arr $arr -Model "X7520" -PartNr "A01-X0209"
  $arr = Add-PartNrRow -arr $arr -Model "E7520" -PartNr "A01-X0209"
  $arr = Add-PartNrRow -arr $arr -Model "X7540" -PartNr "A01-X0203"
  $arr = Add-PartNrRow -arr $arr -Model "E7540" -PartNr "A01-X0203"
  $arr = Add-PartNrRow -arr $arr -Model "X7542" -PartNr "A01-X0202"
  $arr = Add-PartNrRow -arr $arr -Model "X7550" -PartNr "A01-X0201"
  $arr = Add-PartNrRow -arr $arr -Model "L7555" -PartNr "A01-X0206"
  $arr = Add-PartNrRow -arr $arr -Model "X7560" -PartNr "A01-X0200"

  $arr | Export-Csv "C:\Temp\Cpu2PartNr.csv"
  $arr = $null
}

# CPU/GPU Model/PartNr Names
function Get-ModelCPU ([string]$Descr) {

  if ($Descr -match 'Intel.*?([EXL\-57]+\s*\d{4}L*B*\b(\sv[2-9])?)') {
    $Model = $Matches[1] -replace '- ','-' -replace ' v','-v'
  }
  else {
    $Model = ""
  }
  if ($Model -match 'E[57]-.*B$') {
    $Model = $Model -replace 'B$','-v2'
  }
  if (($Model -match 'E[57]-.*') -and (-not ($Model -match '.*-v[2-9]'))) {
    $Model += '-v1'
  }
  if ($Model -eq "E7-L8867-v1") {
    $Model = "E7-8867L-v1"
  }

  return $Model;
}

function Get-PartNrCPU ([string]$Model) {
  if ($Model -Match 'E[57]-d{4}L*-v[1-9]') {
    $PartNr = "UCS-CPU-" + ( $Model -replace '-v1','' -replace '-v2','B' -replace '-v3','D' )
  }
  else { # Read from table
    $c2p = ( Import-Csv -path "C:\Temp\cpu2partnr.csv" | where { $_.Model -eq $Model } )
    $PartNr = $c2p.PartNr
  }

  return $PartNr
}

function Get-ModelGPU ([string]$Descr) {

  if ($Descr -match 'Nvidia.*\s(GRID K[1-9])\s.*') {
    $Model = $Matches[1] -replace 'GRID ','VGX-'
  }
  elseif ($Descr -match 'Nvidia.*\s(TESLA K[1-9]0X*)m*\s.*') {
    $Model = $Matches[1] -replace ' ','-'
  }
  else {
    $Model = ""
  }

  return $Model;
}

function Get-PartNrGPU ([string]$Model) {

  $PartNr = "UCSC-GPU-" + $Model -replace 'VGX-','VGX' -replace 'TESLA-',''

  return $PartNr
}

# Function to Get rows for HTML table
function GetHtmlTableRows($list )
{

    $rows = ""
    foreach($item in $list)
    {  
        $rows +="`n`t`t`t`t`t"
        $rows += "<tr><td>"+$item.Component+"</td><td>"+ $item.Model+"</td><td>"+$item.'Part Nr'+"</td>"
        $rows += "<td>"+$item.Serial+"</td><td>"+$item.Version+"</td><td>"+$item.DN+"</td><td>"+$item.UCS+"</td>"
        $rows += "<td>"+$item.Tag+"</td></tr>"
    }
    return $rows
}

#########################################################################################################################


# Create CSV files for Part2Model / Model2Part filters
Create-ModelTable
Create-OldCpuTable



# Get UID/PWD

<#Try {
  Write-Host "Enter UCS Credentials of UCS Manager(s)"  $user = ""
  $password = "" |
  ConvertTo-SecureString -AsPlainText -Force
  ${ucsCred} = New-Object System.Management.Automation.PSCredential($user, $password)
  
  {ucsCred} = Get-Credential
}
Catch {
  Write-Host "No credential given"
# Write-Host "Error equals: ${Error}"
  Write-Host "Exiting..."
  Write-Host ""
  exit
} #>
Write-Host ""
$ucsClasses = @("networkElement", "equipmentSwitchCard", "equipmentFanModule", "equipmentFan", "equipmentPsu", "equipmentChassis", "equipmentIOCard", "equipmentFex", "computeBlade", "computeRackUnit", "computeBoard", "processorUnit", "memoryArray", "memoryUnit", "storageLocalDisk", "adaptorUnit", "equipmentTpm", "graphicsCard", "storageFlexFlashCard", "firmwareRunning" )

# List of UCS domains
Try {
  [array]$ucsArray = $ucsm.split(",") |%{$_.Trim()}
  if ($ucsArray.Count -eq 0) {
    Write-Host "No valid Hostname"
    Write-Host "Exiting..."
    Write-Host ""
    exit
  }
}
Catch {
  Write-Host "Error parsing Hostnames / IP-addresses"
  Write-Host "Error equals: ${Error}"
  Write-Host "Exiting..."
  Write-Host ""
  exit
}


# Do a PING test on each UCS
foreach ($ucs in $ucsArray) {
  $ping = new-object system.net.networkinformation.ping
  $results = $ping.send($ucs)
  if ($results.Status -ne "Success") {
    Write-Host "Can't ping UCS domain '$($ucs)'"
    #Write-Host "Exiting..."
    #Write-Host ""
    #exit
  }
}

# Loop through UCS domains
$disconnectedUCS = ""
$collectionVariable = @()
foreach ($ucs in $ucsArray) {

  # Connect to (previous) UCS(s)
  Disconnect-Ucs

  # Login into UCS Domain
  Write-Host "UCS Domain '$($ucs)'"

  Try {
    ${ucsCon} = Connect-Ucs -Name ${ucs} -Credential ${credential} -ErrorAction SilentlyContinue
    if ($ucsCon -eq $null) {
      Write-Host "Can't login to: '$($ucs)'"
      if ($disconnectedUCS -eq "") {
        $disconnectedUCS += $($ucs)
      }
      else {
        $disconnectedUCS += ", " + $($ucs)
      }
      #$disconnectedUCS.Add($($ucs))
      continue
      Write-Host "Exiting..."
      Write-Host ""
      exit
    }
#   else {
#     Write-Host "UCS Connection: '$($ucsCon)'"
#   }
  }
  Catch {
    Write-Host "Error creating a session to UCS Manager Domain: '$($ucs)'"
    Write-Host "Error equals: ${Error}"
    Write-Host "Exiting..."
    Write-Host ""
    exit
  }

  Try {
    if ($verb) {
      Write-Host ""
    }
    $ucsClasses | foreach {
      if ($verb) {
        Write-Host "Querying '$($_)'"
      }
      $classId = $($_)
      Invoke-Command -Scriptblock { & Get-UcsManagedObject -classid $_ | Export-Csv -NoType C:\Temp\$($_).csv }
    }
  }
  Catch {
    Write-Host "Error querying Class : '$($classid)'"
    Write-Host "Error equals: ${Error}"
    Write-Host "Exiting..."
    Write-Host ""
    exit
  }

  if ($verb) {
    Write-Host ""
  }

  # Fabric Interconnects plus Parts

  $fis = ( Import-Csv -path "C:\Temp\networkElement.csv" | Sort-Object Id ) # Id is here 'A' or 'B', not numeric
  foreach ($fi in $fis) {
    if ($verb) {
      Write-Host "fi: $($fi.Dn)"
    }

    $p2m = ( Import-Csv -path "C:\Temp\Part2Model.csv" | where { $_.PartNr -like "$($fi.Model)*" } )
    $fws = ( Import-Csv -path "C:\Temp\firmwareRunning.csv" | where { $_.Dn -eq "$($fi.Dn)/mgmt/fw-system" } )

    if ($verb) {
      Write-Host "fw: $($fws.Dn)"
    }
      $item = New-Object System.Object
      $item | Add-Member -MemberType NoteProperty -Name "Component" -Value "Fabric Interconnect $($fi.Id)"
      $item | Add-Member -MemberType NoteProperty -Name "Model" -Value $($p2m.Model)
      $item | Add-Member -MemberType NoteProperty -Name "Part Nr"-Value $($p2m.PartNr)
      $item | Add-Member -MemberType NoteProperty -Name "Serial" -Value $($fi.Serial) 
      $item | Add-Member -MemberType NoteProperty -Name "Version" -Value $fws.Version 
      $item | Add-Member -MemberType NoteProperty -Name "DN" -Value $fi.Dn 
      $item | Add-Member -MemberType NoteProperty -Name "UCS" -Value $ucs
	  $item | Add-Member -MemberType NoteProperty -Name "Tag" -Value $($p2m.Tag)
      $collectionVariable += $item


    if (($show -eq 0) -or ($show -ge 2)) {
      $exp = ( Import-Csv -path "C:\Temp\equipmentSwitchCard.csv" | where { $_.Dn -like "$($fi.Dn)*" } | where { $_.Model -ne "" } | where { $_.Id -gt 1 } | Sort-Object @{exp = {$_.Id -as [int]}} )
      foreach ($ex in $exp) {
        if ($verb) {
          Write-Host "ex: $($ex.Dn)"
        }

        $p2m = ( Import-Csv -path "C:\Temp\Part2Model.csv" | where { $_.PartNr -like "$($ex.Model)*" } )
        $fws = ( Import-Csv -path "C:\Temp\firmwareRunning.csv" | where { $_.Dn -eq "$($ex.Dn)/mgmt/fw-system" } )

        $item = New-Object System.Object
      $item | Add-Member -MemberType NoteProperty -Name "Component" -Value "FI Expansion Module $($ex.Id - 1)"
      $item | Add-Member -MemberType NoteProperty -Name "Model" -Value $($p2m.Model)
      $item | Add-Member -MemberType NoteProperty -Name "Part Nr"-Value $($p2m.PartNr)
      $item | Add-Member -MemberType NoteProperty -Name "Serial" -Value $($ex.Serial) 
      $item | Add-Member -MemberType NoteProperty -Name "Version" -Value $fws.Version 
      $item | Add-Member -MemberType NoteProperty -Name "DN" -Value $ex.Dn 
      $item | Add-Member -MemberType NoteProperty -Name "UCS" -Value $ucs
	  $item | Add-Member -MemberType NoteProperty -Name "Tag" -Value $($p2m.Tag)
      $collectionVariable += $item


      }
    }

    if (($show -eq 0) -or ($show -ge 4)) {
      $psu = ( Import-Csv -path "C:\Temp\equipmentPsu.csv" | where { $_.Dn -like "$($fi.Dn)*" } | where { $_.Model -ne "" } | Sort-Object @{exp = {$_.Id -as [int]}} )
      foreach ($ps in $psu) {
        if ($verb) {
          Write-Host "ps: $($ps.Dn)"
        }

        $p2m = ( Import-Csv -path "C:\Temp\Part2Model.csv" | where { $_.PartNr -like "$($ps.Model)*" } )

          $item = New-Object System.Object
      $item | Add-Member -MemberType NoteProperty -Name "Component" -Value "FI Power Supply $($ps.Id)"
      $item | Add-Member -MemberType NoteProperty -Name "Model" -Value $($p2m.Model)
      $item | Add-Member -MemberType NoteProperty -Name "Part Nr"-Value $($p2m.PartNr)
      $item | Add-Member -MemberType NoteProperty -Name "Serial" -Value $($ps.Serial) 
      $item | Add-Member -MemberType NoteProperty -Name "Version" -Value $fws.Version 
      $item | Add-Member -MemberType NoteProperty -Name "DN" -Value $ps.Dn 
      $item | Add-Member -MemberType NoteProperty -Name "UCS" -Value $ucs
	  $item | Add-Member -MemberType NoteProperty -Name "Tag" -Value $($p2m.Tag)
      $collectionVariable += $item


      }
    }

    if (($show -eq 0) -or ($show -ge 4)) {
      $mod = ( Import-Csv -path "C:\Temp\equipmentFanModule.csv" | where { $_.Dn -like "$($fi.Dn)*" } | where { $_.Model -ne "" } | Sort-Object @{exp = {$_.Id -as [int]}} )
      $fan = ( Import-Csv -path "C:\Temp\equipmentFan.csv" | where { $_.Dn -like "$($fi.Dn)*" } | where { $_.Model -ne "" } | Sort-Object @{exp = {$_.Id -as [int]}} )

      if ($mod.count -ge 0) {

        foreach ($fm in $mod) {
          if ($verb) {
            Write-Host "fm: $($fm.Dn)"
          }

          $p2m = ( Import-Csv -path "C:\Temp\Part2Model.csv" | where { $_.PartNr -like "$($fm.Model)*" } )

          $item = New-Object System.Object
          $item | Add-Member -MemberType NoteProperty -Name "Component" -Value "FI Cooling Fan $($fm.Id)"
          $item | Add-Member -MemberType NoteProperty -Name "Model" -Value $($p2m.Model)
          $item | Add-Member -MemberType NoteProperty -Name "Part Nr"-Value $($p2m.PartNr)
          $item | Add-Member -MemberType NoteProperty -Name "Serial" -Value $($fm.Serial) 
          $item | Add-Member -MemberType NoteProperty -Name "Version" -Value $fws.Version 
          $item | Add-Member -MemberType NoteProperty -Name "DN" -Value $fm.Dn 
          $item | Add-Member -MemberType NoteProperty -Name "UCS" -Value $ucs
		  $item | Add-Member -MemberType NoteProperty -Name "Tag" -Value $($p2m.Tag)
          $collectionVariable += $item


        }

      }
      else { # no fan modules

        foreach ($cf in $fan) {
          if ($verb) {
            Write-Host "cf: $($cf.Dn)"
          }

          $p2m = ( Import-Csv -path "C:\Temp\Part2Model.csv" | where { $_.PartNr -like "$($cf.Model)*" } )

          $item = New-Object System.Object
          $item | Add-Member -MemberType NoteProperty -Name "Component" -Value "FI Cooling Fan $($cf.Id)"
          $item | Add-Member -MemberType NoteProperty -Name "Model" -Value $($p2m.Model)
          $item | Add-Member -MemberType NoteProperty -Name "Part Nr"-Value $($p2m.PartNr)
          $item | Add-Member -MemberType NoteProperty -Name "Serial" -Value $($cf.Serial) 
          $item | Add-Member -MemberType NoteProperty -Name "Version" -Value $fws.Version 
          $item | Add-Member -MemberType NoteProperty -Name "DN" -Value $cf.Dn 
          $item | Add-Member -MemberType NoteProperty -Name "UCS" -Value $ucs
		  $item | Add-Member -MemberType NoteProperty -Name "Tag" -Value $($p2m.Tag)
          $collectionVariable += $item
  
          #if ($summ) {
          #  $worksheet.Cells.Item($row,2) = "Cooling Fans"
          #  $worksheet.Cells.Item($row,6) = @($fan).count
          #  $worksheet.Cells.Item($row,10) = ""
          #  break
          #}
        }

      } # end if module or fan
    }
  }

  # Chassis's plus Parts

  $chs = ( Import-Csv -path "C:\Temp\equipmentChassis.csv" | where { $_.Model -ne "" } | Sort-Object @{exp = {$_.Id -as [int]}} )
  foreach ($ch in $chs) {
    if ($verb) {
      Write-Host "ch: $($ch.Dn)"
    }

    $p2m = ( Import-Csv -path "C:\Temp\Part2Model.csv" | where { $_.PartNr -like "$($ch.Model)*" } )

    $item = New-Object System.Object
    $item | Add-Member -MemberType NoteProperty -Name "Component" -Value "UCS Chassis $($ch.Id)"
    $item | Add-Member -MemberType NoteProperty -Name "Model" -Value $($p2m.Model)
    $item | Add-Member -MemberType NoteProperty -Name "Part Nr"-Value $($p2m.PartNr)
    $item | Add-Member -MemberType NoteProperty -Name "Serial" -Value $($ch.Serial) 
    $item | Add-Member -MemberType NoteProperty -Name "Version" -Value $fws.Version 
    $item | Add-Member -MemberType NoteProperty -Name "DN" -Value $ch.Dn 
    $item | Add-Member -MemberType NoteProperty -Name "UCS" -Value $ucs
	$item | Add-Member -MemberType NoteProperty -Name "Tag" -Value $($p2m.Tag)
    $collectionVariable += $item

    if (($show -eq 0) -or ($show -ge 2)) {
      $iom = ( Import-Csv -path "C:\Temp\equipmentIOCard.csv" | where { $_.Dn -like "$($ch.Dn)*" } | where { $_.Model -ne "" } | Sort-Object @{exp = {$_.Id -as [int]}} )
      foreach ($io in $iom) {
        if ($verb) {
          Write-Host "io: $($io.Dn)"
        }

        $p2m = ( Import-Csv -path "C:\Temp\Part2Model.csv" | where { $_.PartNr -like "$($io.Model)*" } )
        $fws = ( Import-Csv -path "C:\Temp\firmwareRunning.csv" | where { $_.Dn -eq "$($io.Dn)/mgmt/fw-system" } )
        if ($verb) {
          Write-Host "fw: $($fws.Dn)"
        }
        $item = New-Object System.Object
        $item | Add-Member -MemberType NoteProperty -Name "Component" -Value "I/O Module $($io.Id)"
        $item | Add-Member -MemberType NoteProperty -Name "Model" -Value $($p2m.Model)
        $item | Add-Member -MemberType NoteProperty -Name "Part Nr"-Value $($p2m.PartNr)
        $item | Add-Member -MemberType NoteProperty -Name "Serial" -Value $($io.Serial) 
        $item | Add-Member -MemberType NoteProperty -Name "Version" -Value $fws.Version 
        $item | Add-Member -MemberType NoteProperty -Name "DN" -Value $io.Dn 
        $item | Add-Member -MemberType NoteProperty -Name "UCS" -Value $ucs
		$item | Add-Member -MemberType NoteProperty -Name "Tag" -Value $($p2m.Tag)
        $collectionVariable += $item
    
      }
    }

    if (($show -eq 0) -or ($show -ge 4)) {
      $psu = ( Import-Csv -path "C:\Temp\equipmentPsu.csv" | where { $_.Dn -like "$($ch.Dn)*" } | where { $_.Model -ne "" } | Sort-Object @{exp = {$_.Id -as [int]}} )
      foreach ($ps in $psu) {
        if ($verb) {
          Write-Host "ps: $($ps.Dn)"
        }

        $p2m = ( Import-Csv -path "C:\Temp\Part2Model.csv" | where { $_.PartNr -like "$($ps.Model)*" } )
        $item = New-Object System.Object
        $item | Add-Member -MemberType NoteProperty -Name "Component" -Value "Chassis Power Supply $($ps.Id)"
        $item | Add-Member -MemberType NoteProperty -Name "Model" -Value $($p2m.Model)
        $item | Add-Member -MemberType NoteProperty -Name "Part Nr"-Value $($p2m.PartNr)
        $item | Add-Member -MemberType NoteProperty -Name "Serial" -Value $($ps.Serial) 
        $item | Add-Member -MemberType NoteProperty -Name "Version" -Value $fws.Version 
        $item | Add-Member -MemberType NoteProperty -Name "DN" -Value $ps.Dn 
        $item | Add-Member -MemberType NoteProperty -Name "UCS" -Value $ucs
		$item | Add-Member -MemberType NoteProperty -Name "Tag" -Value $($p2m.Tag)
        $collectionVariable += $item
    
      }
    }

    if (($show -eq 0) -or ($show -ge 4)) {
      $mod = ( Import-Csv -path "C:\Temp\equipmentFanModule.csv" | where { $_.Dn -like "$($ch.Dn)*" } | where { $_.Model -ne "" } | Sort-Object @{exp = {$_.Id -as [int]}} )
      $fan = ( Import-Csv -path "C:\Temp\equipmentFan.csv" | where { $_.Dn -like "$($ch.Dn)*" } | where { $_.Model -ne "" } | Sort-Object @{exp = {$_.Id -as [int]}} )

      if ($mod.count -ge 0) {

        foreach ($fm in $mod) {
          if ($verb) {
            Write-Host "cf: $($fm.Dn)"
          }

          $p2m = ( Import-Csv -path "C:\Temp\Part2Model.csv" | where { $_.PartNr -like "$($fm.Model)*" } )

          $item = New-Object System.Object
          $item | Add-Member -MemberType NoteProperty -Name "Component" -Value "Chassis Cooling Fan $($fm.Id)"
          $item | Add-Member -MemberType NoteProperty -Name "Model" -Value $($p2m.Model)
          $item | Add-Member -MemberType NoteProperty -Name "Part Nr"-Value $($p2m.PartNr)
          $item | Add-Member -MemberType NoteProperty -Name "Serial" -Value $($fm.Serial) 
          $item | Add-Member -MemberType NoteProperty -Name "Version" -Value $fws.Version 
          $item | Add-Member -MemberType NoteProperty -Name "DN" -Value $fm.Dn 
          $item | Add-Member -MemberType NoteProperty -Name "UCS" -Value $ucs
		  $item | Add-Member -MemberType NoteProperty -Name "Tag" -Value $($p2m.Tag)
          $collectionVariable += $item
    
        }

      }
      else { # no fan modules

        foreach ($cf in $fan) {
          if ($verb) {
            Write-Host "cf: $($cf.Dn)"
          }

          $p2m = ( Import-Csv -path "C:\Temp\Part2Model.csv" | where { $_.PartNr -like "$($cf.Model)*" } )
          $item = New-Object System.Object
          $item | Add-Member -MemberType NoteProperty -Name "Component" -Value "Chassis Cooling Fan $($cf.Id)"
          $item | Add-Member -MemberType NoteProperty -Name "Model" -Value $($p2m.Model)
          $item | Add-Member -MemberType NoteProperty -Name "Part Nr"-Value $($p2m.PartNr)
          $item | Add-Member -MemberType NoteProperty -Name "Serial" -Value $($cf.Serial) 
          $item | Add-Member -MemberType NoteProperty -Name "Version" -Value $fws.Version 
          $item | Add-Member -MemberType NoteProperty -Name "DN" -Value $cf.Dn 
          $item | Add-Member -MemberType NoteProperty -Name "UCS" -Value $ucs
		  $item | Add-Member -MemberType NoteProperty -Name "Tag" -Value $($p2m.Tag)
          $collectionVariable += $item
    
          <#  
          if ($summ) {
            $worksheet.Cells.Item($row,3) = "Cooling Fans"
            $worksheet.Cells.Item($row,6) = @($fan).count
            $worksheet.Cells.Item($row,10) = ""
            break
          }
          #>
        }

      } # end if module or fan
    }

    # Blades plus Parts

    $bld = ( Import-Csv -path "C:\Temp\computeBlade.csv" | where { $_.Dn -like "$($ch.Dn)*" } | where { $_.Model -ne "" } | Sort-Object @{exp = {$_.Id -as [int]}} )
    foreach ($bl in $bld) {
      if ($verb) {
        Write-Host "bl: $($bl.Dn)"
      }

      $p2m = ( Import-Csv -path "C:\Temp\Part2Model.csv" | where { $_.PartNr -like "$($bl.Model)*" } )
      $fws = ( Import-Csv -path "C:\Temp\firmwareRunning.csv" | where { $_.Dn -eq "$($bl.Dn)/mgmt/fw-system" } )
      if ($verb) {
        Write-Host "fw: $($fws.Dn)"
      }

      $item = New-Object System.Object
      $item | Add-Member -MemberType NoteProperty -Name "Component" -Value "UCS Blade $($bl.SlotId)"
      $item | Add-Member -MemberType NoteProperty -Name "Model" -Value $($p2m.Model)
      $item | Add-Member -MemberType NoteProperty -Name "Part Nr"-Value $($p2m.PartNr)
      $item | Add-Member -MemberType NoteProperty -Name "Serial" -Value $($bl.Serial) 
      $item | Add-Member -MemberType NoteProperty -Name "Version" -Value $fws.Version 
      $item | Add-Member -MemberType NoteProperty -Name "DN" -Value $bl.Dn 
      $item | Add-Member -MemberType NoteProperty -Name "UCS" -Value $ucs
	  $item | Add-Member -MemberType NoteProperty -Name "Tag" -Value $($p2m.Tag)
      $collectionVariable += $item


      if (($show -eq 0) -or ($show -ge 2)) {
        $cpu = ( Import-Csv -path "C:\Temp\processorUnit.csv" | where { $_.Dn -like "$($bl.Dn)*" } | where { $_.Model -ne "" } | Sort-Object @{exp = {$_.Id -as [int]}} )
        foreach ($pr in $cpu) {
          if ($verb) {
            Write-Host "pr: $($pr.Dn)"
          }

#         $c2p = ( Import-Csv -path ".\cpu2partnr.csv" | where { $_.Description -like "$($pr.Model)*" } )

          $m = Get-ModelCPU($pr.Model)
          $p = Get-PartNrCPU($m)
          $item = New-Object System.Object
          $item | Add-Member -MemberType NoteProperty -Name "Component" -Value "Blade Processor $($pr.Id)"
          $item | Add-Member -MemberType NoteProperty -Name "Model" -Value $($p2m.Model)
          $item | Add-Member -MemberType NoteProperty -Name "Part Nr"-Value $($p2m.PartNr)
          $item | Add-Member -MemberType NoteProperty -Name "Serial" -Value $($pr.Serial) 
          $item | Add-Member -MemberType NoteProperty -Name "Version" -Value $fws.Version 
          $item | Add-Member -MemberType NoteProperty -Name "DN" -Value $pr.Dn 
          $item | Add-Member -MemberType NoteProperty -Name "UCS" -Value $ucs
		  $item | Add-Member -MemberType NoteProperty -Name "Tag" -Value $($p2m.Tag)
          $collectionVariable += $item
        }
      }

      if (($show -eq 0) -or ($show -ge 2)) {
        $mem = ( Import-Csv -path "C:\Temp\memoryArray.csv" | where {$_.Presence -ieq "equipped"  -and $_.Dn -like "$($bl.Dn)*" } | Sort-Object @{exp = {$_.Id -as [int]}} ) # careful: Model is empty

        [int]$cap = 0
        foreach ($ma in $mem) {
          if ($verb) {
            Write-Host "ma: $($ma.Dn)"
          }
          $cap += (0 + $ma.CurrCapacity)
        }
        $cap /= 1024

        $dim = ( Import-Csv -path "C:\Temp\memoryUnit.csv" | where { $_.Dn -like "$($bl.Dn)*" } | where { $_.Model -ne "" } | Sort-Object @{exp = {$_.Id -as [int]}} | select -First 1 )
        $dn= $dim.Dn
        if( $dn -eq $null -or $dn -eq ""){
           $temp= (Import-Csv -path "C:\Temp\memoryUnit.csv" | where { $_.Dn -like "$($bl.Dn)*" } | Sort-Object @{exp = {$_.Id -as [int]}} | select -First 1  )
           $dn= $temp.Dn
        }
        if($dn -ne $null -and $dn -ne ""){
             $item = New-Object System.Object
             $item | Add-Member -MemberType NoteProperty -Name "Component" -Value "Blade Memory"
             $item | Add-Member -MemberType NoteProperty -Name "Model" -Value $dim.Model
             $item | Add-Member -MemberType NoteProperty -Name "Size"-Value "$($cap) GB"
             $item | Add-Member -MemberType NoteProperty -Name "DN" -Value $dn 
             $item | Add-Member -MemberType NoteProperty -Name "UCS" -Value $ucs
		     $item | Add-Member -MemberType NoteProperty -Name "Tag" -Value $($p2m.Tag)
             $collectionVariable += $item
         }
      }

      if (($show -ge 5) -and (-not $summ)) {
        $dim = ( Import-Csv -path "C:\Temp\memoryUnit.csv" | where { $_.Dn -like "$($bl.Dn)*" } | where { $_.Model -ne "" } | Sort-Object @{exp = {$_.Id -as [int]}} )
        foreach ($mm in $dim) {
          if ($verb) {
            Write-Host "mm: $($mm.Dn)"
          }

          [int]$cap = 0 + $mm.Capacity
          $cap /= 1024
         $item = New-Object System.Object
         $item | Add-Member -MemberType NoteProperty -Name "Component" -Value "Module $($mm.Id)"
         $item | Add-Member -MemberType NoteProperty -Name "Model" -Value $mm.Model
         $item | Add-Member -MemberType NoteProperty -Name "Size"-Value "$($cap) GB"
         $item | Add-Member -MemberType NoteProperty -Name "Serial" -Value $mm.Serial
         $item | Add-Member -MemberType NoteProperty -Name "DN" -Value $mm.Dn 
         $item | Add-Member -MemberType NoteProperty -Name "UCS" -Value $ucs
		 $item | Add-Member -MemberType NoteProperty -Name "Tag" -Value $($p2m.Tag)
         $collectionVariable += $item
        }
      }

      if (($show -eq 0) -or ($show -ge 3)) {
        $hdd = ( Import-Csv -path "C:\Temp\storageLocalDisk.csv" | where { $_.Dn -like "$($bl.Dn)*" } | where { $_.Model -ne "" } | Sort-Object @{exp = {$_.Id -as [int]}} )
        foreach ($hd in $hdd) {
          if ($verb) {
            Write-Host "hd: $($hd.Dn)"
          }

          # old disks (73/146 GB) report too low size (like 70136 MB), newer disks report correct size but in kB
          [double]$sz = 0.0 + $hd.size
          [int]$gb = 0
          if ($sz -ge (1024 * 1024)) {
            $sz /= (1024 * 1024);
            $gb = 10 * [int][Math]::floor($sz / 10.0 + 0.5);
          }
          else {
            $sz = $sz / 960.0
            if (($sz -ge 68.0) -and ($sz -le 78.0)) {
              $gb = 73;
            }
            elseif (($sz -ge 90.0) -and ($sz -le 110.0)) {
              $gb = 100;
            }
            elseif (($sz -ge 136.0) -and ($sz -le 156.0)) {
              $gb = 146;
            }
            else {
              $gb = 20 * [int][Math]::floor($sz / 20.0 + 0.5);
            }
          }
          $item = New-Object System.Object
         $item | Add-Member -MemberType NoteProperty -Name "Component" -Value "Hard Drive $($hd.Id)"
         $item | Add-Member -MemberType NoteProperty -Name "Model" -Value $hd.Model
         $item | Add-Member -MemberType NoteProperty -Name "Size"-Value "$($gb) GB"
         $item | Add-Member -MemberType NoteProperty -Name "Serial" -Value $hd.Serial
         $item | Add-Member -MemberType NoteProperty -Name "DN" -Value $hd.Dn 
         $item | Add-Member -MemberType NoteProperty -Name "UCS" -Value $ucs
		 $item | Add-Member -MemberType NoteProperty -Name "Tag" -Value $($p2m.Tag)
         $collectionVariable += $item
     
        }
      }

      if (($show -eq 0) -or ($show -ge 3)) {
      $gpu = ( Import-Csv -path "C:\Temp\graphicsCard.csv" | where { $_.Dn -like "$($bl.Dn)*" } | where { $_.Model -ne "" } | Sort-Object @{exp = {$_.Id -as [int]}} )
      foreach ($gc in $gpu) {
        if ($verb) {
          Write-Host "gc: $($gc.Dn)"
        }

        $m = Get-ModelGPU($gc.Model)
        $p = Get-PartNrGPU($m)

        $p2m = ( Import-Csv -path "C:\Temp\Part2Model.csv" | where { $_.PartNr -like "$($gc.Model)*" } )
#        $c2p = ( Import-Csv -path ".\gpu2partnr.csv" | where { $_.Description -like "$($gc.Model)*" } )

        $fws = ( Import-Csv -path "C:\Temp\firmwareRunning.csv" | where { $_.Dn -eq "$($gc.Dn)/mgmt/fw-system" } )
        if ($verb) {
          Write-Host "fw: $($fws.Dn)"
        }
        $item = New-Object System.Object
          $item | Add-Member -MemberType NoteProperty -Name "Component" -Value "Blade Graphics Card $($gc.Id)"
          $item | Add-Member -MemberType NoteProperty -Name "Model" -Value $m
          $item | Add-Member -MemberType NoteProperty -Name "Part Nr"-Value $p
          $item | Add-Member -MemberType NoteProperty -Name "Serial" -Value $($gc.Serial) 
          $item | Add-Member -MemberType NoteProperty -Name "Version" -Value $fws.Version 
          $item | Add-Member -MemberType NoteProperty -Name "DN" -Value $gc.Dn 
          $item | Add-Member -MemberType NoteProperty -Name "UCS" -Value $ucs
		  $item | Add-Member -MemberType NoteProperty -Name "Tag" -Value $($p2m.Tag)
          $collectionVariable += $item
      }
    }
     if (($show -eq 0) -or ($show -ge 3)) {
      $tpms = ( Import-Csv -path "C:\Temp\equipmentTpm.csv" | where { $_.Dn -like "$($bl.Dn)*" } | where { $_.Model -ne "" } | Sort-Object @{exp = {$_.Id -as [int]}} )
      foreach ($tpm in $tpms) {
        if ($verb) {
          Write-Host "tpm: $($tpm.Dn)"
        }
        $p2m = ( Import-Csv -path "C:\Temp\Part2Model.csv" | where { $_.PartNr -like "$($tpm.Model)*" } )
       
        $item = New-Object System.Object
          $item | Add-Member -MemberType NoteProperty -Name "Component" -Value "Blade TPM $($tpm.Id)"
          $item | Add-Member -MemberType NoteProperty -Name "Model" -Value $tpm.Model
          $item | Add-Member -MemberType NoteProperty -Name "Part Nr"-Value ""
          $item | Add-Member -MemberType NoteProperty -Name "Serial" -Value $tpm.Serial 
          $item | Add-Member -MemberType NoteProperty -Name "Version" -Value "" 
          $item | Add-Member -MemberType NoteProperty -Name "DN" -Value $tpm.Dn 
          $item | Add-Member -MemberType NoteProperty -Name "UCS" -Value $ucs
		  $item | Add-Member -MemberType NoteProperty -Name "Tag" -Value $($p2m.Tag)
          $collectionVariable += $item
      }
    }

     if (($show -eq 0) -or ($show -ge 3)) {
      $ffCards = ( Import-Csv -path "C:\Temp\storageFlexFlashCard.csv" | where { $_.Dn -like "$($bl.Dn)*" } | where { $_.Model -ne "" } | Sort-Object @{exp = {$_.Id -as [int]}} )
      foreach ($ffCard in $ffCards) {
        if ($verb) {
          Write-Host "tpm: $($ffCard.Dn)"
        }
        $p2m = ( Import-Csv -path "C:\Temp\Part2Model.csv" | where { $_.PartNr -like "$($ffCard.Model)*" } )
       
        $item = New-Object System.Object
          $item | Add-Member -MemberType NoteProperty -Name "Component" -Value "Blade FlexFlash $($ffCard.Id)"
          $item | Add-Member -MemberType NoteProperty -Name "Model" -Value $ffCard.Model
          $item | Add-Member -MemberType NoteProperty -Name "Part Nr"-Value ""
          $item | Add-Member -MemberType NoteProperty -Name "Serial" -Value $ffCard.Serial 
          $item | Add-Member -MemberType NoteProperty -Name "Version" -Value "" 
          $item | Add-Member -MemberType NoteProperty -Name "DN" -Value $ffCard.Dn 
          $item | Add-Member -MemberType NoteProperty -Name "UCS" -Value $ucs
		  $item | Add-Member -MemberType NoteProperty -Name "Tag" -Value $($p2m.Tag)
          $collectionVariable += $item
      }
    }


      if (($show -eq 0) -or ($show -ge 3)) {
        $ioa = ( Import-Csv -path "C:\Temp\adaptorUnit.csv" | where { $_.Dn -like "$($bl.Dn)*" } | where { $_.Model -ne "" } | Sort-Object @{exp = {$_.Id -as [int]}} )
        foreach ($io in $ioa) {
          if ($verb) {
            Write-Host "io: $($io.Dn)"
          }

          $p2m = ( Import-Csv -path "C:\Temp\Part2Model.csv" | where { $_.PartNr -like "$($io.Model)*" } )
          $fws = ( Import-Csv -path "C:\Temp\firmwareRunning.csv" | where { $_.Dn -eq "$($io.Dn)/mgmt/fw-system" } )
          if ($verb) {
            Write-Host "fw: $($fws.Dn)"
          }
          $item = New-Object System.Object
          $item | Add-Member -MemberType NoteProperty -Name "Component" -Value "UCS Blade I/O Adaptor $($io.Id)"
          $item | Add-Member -MemberType NoteProperty -Name "Model" -Value $($p2m.Model)
          $item | Add-Member -MemberType NoteProperty -Name "Part Nr"-Value $($p2m.PartNr)
          $item | Add-Member -MemberType NoteProperty -Name "Serial" -Value $($io.Serial) 
          $item | Add-Member -MemberType NoteProperty -Name "Version" -Value $fws.Version 
          $item | Add-Member -MemberType NoteProperty -Name "DN" -Value $io.Dn 
          $item | Add-Member -MemberType NoteProperty -Name "UCS" -Value $ucs
		  $item | Add-Member -MemberType NoteProperty -Name "Tag" -Value $($p2m.Tag)
          $collectionVariable += $item

        }
      }
    }
  }

  # Rackmounts plus Parts

  $fex = ( Import-Csv -path "C:\Temp\equipmentFex.csv" | where { $_.Model -ne "" } | Sort-Object @{exp = {$_.Id -as [int]}} )
  $srv = ( Import-Csv -path "C:\Temp\computeRackUnit.csv" | where { $_.Model -ne "" } | Sort-Object @{exp = {$_.Id -as [int]}} )
  $fex = ( Import-Csv -path "C:\Temp\equipmentFex.csv" | where { $_.Model -ne "" } | Sort-Object @{exp = {$_.Id -as [int]}} )
  foreach ($fx in $fex) {
    if ($verb) {
      Write-Host "fx: $($fx.Dn)"
    }

    $p2m = ( Import-Csv -path "C:\Temp\Part2Model.csv" | where { $_.PartNr -like "$($fx.Model)*" } )
    $fws = ( Import-Csv -path "C:\Temp\firmwareRunning.csv" | where { $_.Dn -eq "$($fx.Dn)/slot-1/mgmt/fw-system" } )

    if ($verb) {
      Write-Host "fw: $($fws.Dn)"
    }
    $item = New-Object System.Object
          $item | Add-Member -MemberType NoteProperty -Name "Component" -Value "Fabric Extender $($fx.Id)"
          $item | Add-Member -MemberType NoteProperty -Name "Model" -Value $($p2m.Model)
          $item | Add-Member -MemberType NoteProperty -Name "Part Nr"-Value $($p2m.PartNr)
          $item | Add-Member -MemberType NoteProperty -Name "Serial" -Value $($fx.Serial) 
          $item | Add-Member -MemberType NoteProperty -Name "Version" -Value $fws.Version 
          $item | Add-Member -MemberType NoteProperty -Name "DN" -Value $fx.Dn 
          $item | Add-Member -MemberType NoteProperty -Name "UCS" -Value $ucs
		  $item | Add-Member -MemberType NoteProperty -Name "Tag" -Value $($p2m.Tag)
          $collectionVariable += $item


    if (($show -eq 0) -or ($show -ge 4)) {
      $psu = ( Import-Csv -path "C:\Temp\equipmentPsu.csv" | where { $_.Dn -like "$($fx.Dn)*" } | where { $_.Model -ne "" } | Sort-Object @{exp = {$_.Id -as [int]}} )
      foreach ($ps in $psu) {
        if ($verb) {
          Write-Host "ps: $($ps.Dn)"
        }

        $p2m = ( Import-Csv -path "C:\Temp\Part2Model.csv" | where { $_.PartNr -like "$($ps.Model)*" } )
        $item = New-Object System.Object
          $item | Add-Member -MemberType NoteProperty -Name "Component" -Value "Fabric Extender Power Supply $($ps.Id)"
          $item | Add-Member -MemberType NoteProperty -Name "Model" -Value $($p2m.Model)
          $item | Add-Member -MemberType NoteProperty -Name "Part Nr"-Value $($p2m.PartNr)
          $item | Add-Member -MemberType NoteProperty -Name "Serial" -Value $($ps.Serial) 
          $item | Add-Member -MemberType NoteProperty -Name "Version" -Value $fws.Version 
          $item | Add-Member -MemberType NoteProperty -Name "DN" -Value $ps.Dn 
          $item | Add-Member -MemberType NoteProperty -Name "UCS" -Value $ucs
		  $item | Add-Member -MemberType NoteProperty -Name "Tag" -Value $($p2m.Tag)
          $collectionVariable += $item
      }
    }

    if (($show -eq 0) -or ($show -ge 4)) {
      $mod = ( Import-Csv -path "C:\Temp\equipmentFanModule.csv" | where { $_.Dn -like "$($fx.Dn)*" } | where { $_.Model -ne "" } | where { $_.Id -eq "1" } | Sort-Object @{exp = {$_.Id -as [int]}} )
      $fan = ( Import-Csv -path "C:\Temp\equipmentFan.csv" | where { $_.Dn -like "$($fx.Dn)*" } | where { $_.Model -ne "" } | where { $_.Id -eq "1" } | Sort-Object @{exp = {$_.Id -as [int]}} )
      if ($mod.count -ge 0) {

        foreach ($fm in $mod) {
          if ($verb) {
            Write-Host "fm: $($fm.Dn)"
          }

          $p2m = ( Import-Csv -path "C:\Temp\Part2Model.csv" | where { $_.PartNr -like "$($fm.Model)*" } )
        $item = New-Object System.Object
          $item | Add-Member -MemberType NoteProperty -Name "Component" -Value "Fabric Extender Cooling Fan $($fm.Id)"
          $item | Add-Member -MemberType NoteProperty -Name "Model" -Value $($p2m.Model)
          $item | Add-Member -MemberType NoteProperty -Name "Part Nr"-Value $($p2m.PartNr)
          $item | Add-Member -MemberType NoteProperty -Name "Serial" -Value $($fm.Serial) 
          $item | Add-Member -MemberType NoteProperty -Name "Version" -Value $fws.Version 
          $item | Add-Member -MemberType NoteProperty -Name "DN" -Value $fm.Dn 
          $item | Add-Member -MemberType NoteProperty -Name "UCS" -Value $ucs
		  $item | Add-Member -MemberType NoteProperty -Name "Tag" -Value $($p2m.Tag)
          $collectionVariable += $item
        }

      }
      else { # no fan modules

        foreach ($cf in $fan) {
          if ($verb) {
            Write-Host "cf: $($cf.Dn)"
          }

          $p2m = ( Import-Csv -path "C:\Temp\Part2Model.csv" | where { $_.PartNr -like "$($cf.Model)*" } )
          $item = New-Object System.Object
          $item | Add-Member -MemberType NoteProperty -Name "Component" -Value "Fabric Extender Cooling Fan $($cf.Id)"
          $item | Add-Member -MemberType NoteProperty -Name "Model" -Value $($p2m.Model)
          $item | Add-Member -MemberType NoteProperty -Name "Part Nr"-Value $($p2m.PartNr)
          $item | Add-Member -MemberType NoteProperty -Name "Serial" -Value $($cf.Serial) 
          $item | Add-Member -MemberType NoteProperty -Name "Version" -Value $fws.Version 
          $item | Add-Member -MemberType NoteProperty -Name "DN" -Value $cf.Dn 
          $item | Add-Member -MemberType NoteProperty -Name "UCS" -Value $ucs
		  $item | Add-Member -MemberType NoteProperty -Name "Tag" -Value $($p2m.Tag)
          $collectionVariable += $item

        }

      } # end if module or fan
    }
  }

  $srv = ( Import-Csv -path "C:\Temp\computeRackUnit.csv" | where { $_.Model -ne "" } | Sort-Object @{exp = {$_.Id -as [int]}} )
  foreach ($sv in $srv) {
    if ($verb) {
      Write-Host "sv: $($sv.Dn)"
    }

    $p2m = ( Import-Csv -path "C:\Temp\Part2Model.csv" | where { $_.PartNr -like "$($sv.Model)*" } )
    $fws = ( Import-Csv -path "C:\Temp\firmwareRunning.csv" | where { $_.Dn -eq "$($sv.Dn)/mgmt/fw-system" } )
    if ($verb) {
      Write-Host "fw: $($fws.Dn)"
    }
    $item = New-Object System.Object
          $item | Add-Member -MemberType NoteProperty -Name "Component" -Value "Rack Server $($sv.Id)"
          $item | Add-Member -MemberType NoteProperty -Name "Model" -Value $($p2m.Model)
          $item | Add-Member -MemberType NoteProperty -Name "Part Nr"-Value $($p2m.PartNr)
          $item | Add-Member -MemberType NoteProperty -Name "Serial" -Value $($sv.Serial) 
          $item | Add-Member -MemberType NoteProperty -Name "Version" -Value $fws.Version 
          $item | Add-Member -MemberType NoteProperty -Name "DN" -Value $sv.Dn 
          $item | Add-Member -MemberType NoteProperty -Name "UCS" -Value $ucs
		  $item | Add-Member -MemberType NoteProperty -Name "Tag" -Value $($p2m.Tag)
          $collectionVariable += $item
    

    if (($show -eq 0) -or ($show -ge 2)) {
      $cpu = ( Import-Csv -path "C:\Temp\processorUnit.csv" | where { $_.Dn -like "$($sv.Dn)*" } | where { $_.Model -ne "" } | Sort-Object @{exp = {$_.Id -as [int]}} )
      foreach ($pr in $cpu) {
        if ($verb) {
          Write-Host "pr: $($pr.Dn)"
        }

#       $c2p = ( Import-Csv -path ".\cpu2partnr.csv" | where { $_.Description -like "$($pr.Model)*" } )

        $m = Get-ModelCPU($pr.Model)
        $p = Get-PartNrCPU($m)
          $item = New-Object System.Object
          $item | Add-Member -MemberType NoteProperty -Name "Component" -Value "Rack Server Processor $($pr.Id)"
          $item | Add-Member -MemberType NoteProperty -Name "Model" -Value $($p2m.Model)
          $item | Add-Member -MemberType NoteProperty -Name "Part Nr"-Value $($p2m.PartNr)
          $item | Add-Member -MemberType NoteProperty -Name "Serial" -Value $($pr.Serial) 
          $item | Add-Member -MemberType NoteProperty -Name "Version" -Value $fws.Version 
          $item | Add-Member -MemberType NoteProperty -Name "DN" -Value $pr.Dn 
          $item | Add-Member -MemberType NoteProperty -Name "UCS" -Value $ucs
		  $item | Add-Member -MemberType NoteProperty -Name "Tag" -Value $($p2m.Tag)
          $collectionVariable += $item

      }
    }

    if (($show -eq 0) -or ($show -ge 2)) {
      $mem = ( Import-Csv -path "C:\Temp\memoryArray.csv" | where { $_.Presence -ieq "equipped"  -and $_.Dn -like "$($sv.Dn)*" } | Sort-Object @{exp = {$_.Id -as [int]}} ) # careful: Model is empty

      [int]$cap = 0
      foreach ($ma in $mem) {
        if ($verb) {
          Write-Host "ma: $($ma.Dn)"
        }
        $cap += (0 + $ma.CurrCapacity)
      }
      $cap /= 1024

      $dim = ( Import-Csv -path "C:\Temp\memoryUnit.csv" | where { $_.Dn -like "$($sv.Dn)*" } | where { $_.Model -ne "" } | Sort-Object @{exp = {$_.Id -as [int]}} | Select -First 1 )
      $dn= $dim.Dn
      if( $dn -eq $null -or $dn -eq ""){
        $temp= (Import-Csv -path "C:\Temp\memoryUnit.csv" | where { $_.Dn -like "$($sv.Dn)*" } | Sort-Object @{exp = {$_.Id -as [int]}} | select -First 1  )
        $dn= $temp.Dn
      } 
      if($dn -ne $null -and $dn -ne "")
      {
         $item = New-Object System.Object
         $item | Add-Member -MemberType NoteProperty -Name "Component" -Value "Rack Server Memory"
         $item | Add-Member -MemberType NoteProperty -Name "Model" -Value $dim.Model
         $item | Add-Member -MemberType NoteProperty -Name "Size"-Value "$($cap) GB"
         $item | Add-Member -MemberType NoteProperty -Name "DN" -Value $dn 
         $item | Add-Member -MemberType NoteProperty -Name "UCS" -Value $ucs
		 $item | Add-Member -MemberType NoteProperty -Name "Tag" -Value $($p2m.Tag)
         $collectionVariable += $item
    }
    
    }

    if (($show -ge 5) -and (-not $summ)) {
      $dim = ( Import-Csv -path "C:\Temp\memoryUnit.csv" | where { $_.Dn -like "$($sv.Dn)*" } | where { $_.Model -ne "" } | Sort-Object @{exp = {$_.Id -as [int]}} )
      foreach ($mm in $dim) {
        if ($verb) {
          Write-Host "mm: $($mm.Dn)"
        }

        [int]$cap = 0 + $mm.Capacity
        $cap /= 1024
        $item = New-Object System.Object
         $item | Add-Member -MemberType NoteProperty -Name "Component" -Value "Module $($mm.Id)"
         $item | Add-Member -MemberType NoteProperty -Name "Model" -Value $mm.Model
         $item | Add-Member -MemberType NoteProperty -Name "Size"-Value "$($cap) GB"
         $item | Add-Member -MemberType NoteProperty -Name "Serial" -Value $dim.Serial
         $item | Add-Member -MemberType NoteProperty -Name "DN" -Value $mm.Dn 
         $item | Add-Member -MemberType NoteProperty -Name "UCS" -Value $ucs
		 $item | Add-Member -MemberType NoteProperty -Name "Tag" -Value $($p2m.Tag)
         $collectionVariable += $item
      }
    }

    if (($show -eq 0) -or ($show -ge 3)) {
      $hdd = ( Import-Csv -path "C:\Temp\storageLocalDisk.csv" | where { $_.Dn -like "$($sv.Dn)*" } | where { $_.Model -ne "" } | Sort-Object @{exp = {$_.Id -as [int]}} )
      foreach ($hd in $hdd) {
        if ($verb) {
          Write-Host "hd: $($hd.Dn)"
        }

        # old disks (73/146 GB) report too low size (like 70136 MB), newer disks report correct size but in kB
        [double]$sz = 0.0 + $hd.size
        [int]$gb = 0
        if ($sz -ge (1024 * 1024)) {
          $sz /= (1024 * 1024);
          $gb = 10 * [int][Math]::floor($sz / 10.0 + 0.5);
        }
        else {
          $sz = $sz / 960.0
          if (($sz -ge 68.0) -and ($sz -le 78.0)) {
            $gb = 73;
          }
          elseif (($sz -ge 90.0) -and ($sz -le 110.0)) {
            $gb = 100;
          }
          elseif (($sz -ge 136.0) -and ($sz -le 156.0)) {
            $gb = 146;
          }
          else {
            $gb = 20 * [int][Math]::floor($sz / 20.0 + 0.5);
          }
        }
         $item = New-Object System.Object
         $item | Add-Member -MemberType NoteProperty -Name "Component" -Value "Hard Drive $($hd.Id)"
         $item | Add-Member -MemberType NoteProperty -Name "Model" -Value $hd.Model
         $item | Add-Member -MemberType NoteProperty -Name "Size"-Value "$($gb) GB"
         $item | Add-Member -MemberType NoteProperty -Name "Serial" -Value $hd.Serial
         $item | Add-Member -MemberType NoteProperty -Name "DN" -Value $hd.Dn 
         $item | Add-Member -MemberType NoteProperty -Name "UCS" -Value $ucs
		 $item | Add-Member -MemberType NoteProperty -Name "Tag" -Value $($p2m.Tag)
         $collectionVariable += $item

      }
    }

    if (($show -eq 0) -or ($show -ge 3)) {
      $gpu = ( Import-Csv -path "C:\Temp\graphicsCard.csv" | where { $_.Dn -like "$($sv.Dn)*" } | where { $_.Model -ne "" } | Sort-Object @{exp = {$_.Id -as [int]}} )
      foreach ($gc in $gpu) {
        if ($verb) {
          Write-Host "gc: $($gc.Dn)"
        }

        $m = Get-ModelGPU($gc.Model)
        $p = Get-PartNrGPU($m)

        $p2m = ( Import-Csv -path "C:\Temp\Part2Model.csv" | where { $_.PartNr -like "$($gc.Model)*" } )
#        $c2p = ( Import-Csv -path ".\gpu2partnr.csv" | where { $_.Description -like "$($gc.Model)*" } )

        $fws = ( Import-Csv -path "C:\Temp\firmwareRunning.csv" | where { $_.Dn -eq "$($gc.Dn)/mgmt/fw-system" } )
        if ($verb) {
          Write-Host "fw: $($fws.Dn)"
        }
        $item = New-Object System.Object
          $item | Add-Member -MemberType NoteProperty -Name "Component" -Value "Rack Server Graphics Card $($gc.Id)"
          $item | Add-Member -MemberType NoteProperty -Name "Model" -Value $m
          $item | Add-Member -MemberType NoteProperty -Name "Part Nr"-Value $p
          $item | Add-Member -MemberType NoteProperty -Name "Serial" -Value $($gc.Serial) 
          $item | Add-Member -MemberType NoteProperty -Name "Version" -Value $fws.Version 
          $item | Add-Member -MemberType NoteProperty -Name "DN" -Value $gc.Dn 
          $item | Add-Member -MemberType NoteProperty -Name "UCS" -Value $ucs
		  $item | Add-Member -MemberType NoteProperty -Name "Tag" -Value $($p2m.Tag)
          $collectionVariable += $item
      }
    }

     if (($show -eq 0) -or ($show -ge 3)) {
      $tpms = ( Import-Csv -path "C:\Temp\equipmentTpm.csv" | where { $_.Dn -like "$($sv.Dn)*" } | where { $_.Model -ne "" } | Sort-Object @{exp = {$_.Id -as [int]}} )
      foreach ($tpm in $tpms) {
        if ($verb) {
          Write-Host "tpm: $($tpm.Dn)"
        }
        $p2m = ( Import-Csv -path "C:\Temp\Part2Model.csv" | where { $_.PartNr -like "$($tpm.Model)*" } )
       
        $item = New-Object System.Object
          $item | Add-Member -MemberType NoteProperty -Name "Component" -Value "Rack Server TPM $($tpm.Id)"
          $item | Add-Member -MemberType NoteProperty -Name "Model" -Value $tpm.Model
          $item | Add-Member -MemberType NoteProperty -Name "Part Nr"-Value ""
          $item | Add-Member -MemberType NoteProperty -Name "Serial" -Value $tpm.Serial 
          $item | Add-Member -MemberType NoteProperty -Name "Version" -Value "" 
          $item | Add-Member -MemberType NoteProperty -Name "DN" -Value $tpm.Dn 
          $item | Add-Member -MemberType NoteProperty -Name "UCS" -Value $ucs
		  $item | Add-Member -MemberType NoteProperty -Name "Tag" -Value $($p2m.Tag)
          $collectionVariable += $item
      }
    }

     if (($show -eq 0) -or ($show -ge 3)) {
      $ffCards = ( Import-Csv -path "C:\Temp\storageFlexFlashCard.csv" | where { $_.Dn -like "$($sv.Dn)*" } | where { $_.Model -ne "" } | Sort-Object @{exp = {$_.Id -as [int]}} )
      foreach ($ffCard in $ffCards) {
        if ($verb) {
          Write-Host "tpm: $($ffCard.Dn)"
        }
        $p2m = ( Import-Csv -path "C:\Temp\Part2Model.csv" | where { $_.PartNr -like "$($ffCard.Model)*" } )
       
        $item = New-Object System.Object
          $item | Add-Member -MemberType NoteProperty -Name "Component" -Value "Rack Server FlexFlash $($ffCard.Id)"
          $item | Add-Member -MemberType NoteProperty -Name "Model" -Value $ffCard.Model
          $item | Add-Member -MemberType NoteProperty -Name "Part Nr"-Value ""
          $item | Add-Member -MemberType NoteProperty -Name "Serial" -Value $ffCard.Serial 
          $item | Add-Member -MemberType NoteProperty -Name "Version" -Value "" 
          $item | Add-Member -MemberType NoteProperty -Name "DN" -Value $ffCard.Dn 
          $item | Add-Member -MemberType NoteProperty -Name "UCS" -Value $ucs
		  $item | Add-Member -MemberType NoteProperty -Name "Tag" -Value $($p2m.Tag)
          $collectionVariable += $item
      }
    }




    if (($show -eq 0) -or ($show -ge 3)) {
      $ioa = ( Import-Csv -path "C:\Temp\adaptorUnit.csv" | where { $_.Dn -like "$($sv.Dn)*" } | where { $_.Model -ne "" } | Sort-Object @{exp = {$_.Id -as [int]}} )
      foreach ($io in $ioa) {
        if ($verb) {
          Write-Host "io: $($io.Dn)"
        }

        $p2m = ( Import-Csv -path "C:\Temp\Part2Model.csv" | where { $_.PartNr -like "$($io.Model)*" } )
        $fws = ( Import-Csv -path "C:\Temp\firmwareRunning.csv" | where { $_.Dn -eq "$($io.Dn)/mgmt/fw-system" } )
        if ($verb) {
          Write-Host "fw: $($fws.Dn)"
        }
        $item = New-Object System.Object
          $item | Add-Member -MemberType NoteProperty -Name "Component" -Value "Rack Server I/O Adaptor $($io.Id)"
          $item | Add-Member -MemberType NoteProperty -Name "Model" -Value $($p2m.Model)
          $item | Add-Member -MemberType NoteProperty -Name "Part Nr"-Value $($p2m.PartNr)
          $item | Add-Member -MemberType NoteProperty -Name "Serial" -Value $($io.Serial) 
          $item | Add-Member -MemberType NoteProperty -Name "Version" -Value $fws.Version 
          $item | Add-Member -MemberType NoteProperty -Name "DN" -Value $io.Dn 
          $item | Add-Member -MemberType NoteProperty -Name "UCS" -Value $ucs
		  $item | Add-Member -MemberType NoteProperty -Name "Tag" -Value $($p2m.Tag)
          $collectionVariable += $item

      }
    }

    if (($show -eq 0) -or ($show -ge 4)) {
      $psu = ( Import-Csv -path "C:\Temp\equipmentPsu.csv" | where { $_.Dn -like "$($sv.Dn)*" } | where { $_.Model -ne "" } | Sort-Object @{exp = {$_.Id -as [int]}} )
      foreach ($ps in $psu) {
        if ($verb) {
          Write-Host "ps: $($ps.Dn)"
        }

        $p2m = ( Import-Csv -path "C:\Temp\Part2Model.csv" | where { $_.PartNr -like "$($ps.Model)*" } )
        $item = New-Object System.Object
          $item | Add-Member -MemberType NoteProperty -Name "Component" -Value "Rack Server Power Supply $($ps.Id)"
          $item | Add-Member -MemberType NoteProperty -Name "Model" -Value  $($p2m.Model)
          $item | Add-Member -MemberType NoteProperty -Name "Part Nr"-Value $($p2m.PartNr)
          $item | Add-Member -MemberType NoteProperty -Name "Serial" -Value $($ps.Serial) 
          $item | Add-Member -MemberType NoteProperty -Name "Version" -Value $fws.Version 
          $item | Add-Member -MemberType NoteProperty -Name "DN" -Value $ps.Dn 
          $item | Add-Member -MemberType NoteProperty -Name "UCS" -Value $ucs
		  $item | Add-Member -MemberType NoteProperty -Name "Tag" -Value $($p2m.Tag)
          $collectionVariable += $item
      }
    }

    if (($show -eq 0) -or ($show -ge 4)) {
      $mod = ( Import-Csv -path "C:\Temp\equipmentFanModule.csv" | where { $_.Dn -like "$($sv.Dn)*" } | Sort-Object @{exp = {$_.Id -as [int]}} )
      $fan = ( Import-Csv -path "C:\Temp\equipmentFan.csv" | where { $_.Dn -like "$($sv.Dn)*" } | Sort-Object @{exp = {$_.Id -as [int]}} )

      if ($mod.count -ge 0) {

        foreach ($fm in $mod) {
          if ($verb) {
            Write-Host "fm: $($fm.Dn)"
          }
        if(-not [System.String]::IsNullOrEmpty($fm.Model))
        {
            $p2m = ( Import-Csv -path "C:\Temp\Part2Model.csv" | where { $_.PartNr -like "$($fm.Model)*" } )
        }
        $item = New-Object System.Object
          $item | Add-Member -MemberType NoteProperty -Name "Component" -Value "Rack Server Cooling Fan $($fm.Id)"
          $item | Add-Member -MemberType NoteProperty -Name "Model" -Value $($p2m.Model)
          $item | Add-Member -MemberType NoteProperty -Name "Part Nr"-Value $($p2m.PartNr)
          $item | Add-Member -MemberType NoteProperty -Name "Serial" -Value $($fm.Serial) 
          $item | Add-Member -MemberType NoteProperty -Name "Version" -Value $fws.Version 
          $item | Add-Member -MemberType NoteProperty -Name "DN" -Value $fm.Dn 
          $item | Add-Member -MemberType NoteProperty -Name "UCS" -Value $ucs
		  $item | Add-Member -MemberType NoteProperty -Name "Tag" -Value $($p2m.Tag)
          $collectionVariable += $item

        }

      }
      else { # no fan modules

        foreach ($cf in $fan) {
          if ($verb) {
            Write-Host "cf: $($cf.Dn)"
          }
          $p2m = ( Import-Csv -path "C:\Temp\Part2Model.csv" | where { $_.PartNr -like "$($cf.Model)*" } )
          $item = New-Object System.Object
          $item | Add-Member -MemberType NoteProperty -Name "Component" -Value "Rack Server Cooling Fan $($cf.Id)"
          $item | Add-Member -MemberType NoteProperty -Name "Model" -Value $($p2m.Model)
          $item | Add-Member -MemberType NoteProperty -Name "Part Nr"-Value ""+ $($p2m.PartNr)
          $item | Add-Member -MemberType NoteProperty -Name "Serial" -Value $($cf.Serial) 
          $item | Add-Member -MemberType NoteProperty -Name "Version" -Value $fws.Version 
          $item | Add-Member -MemberType NoteProperty -Name "DN" -Value $cf.Dn 
          $item | Add-Member -MemberType NoteProperty -Name "UCS" -Value $ucs
		  $item | Add-Member -MemberType NoteProperty -Name "Tag" -Value $($p2m.Tag)
          $collectionVariable += $item
        }

      } # end if module or fan
    }

  }

  if ($verb) {
    Write-Host ""  
  }
  #$collectionVariable | ConvertTo-Html | Out-File -Append c:\vaibjain.html
      
Disconnect-Ucs
Write-Host "Logout from '$($ucs)'"
} # end loop $ucs
#Write-Output "Disconnected UCS Domains: ", $disconnectedUCS | Out-File "C:\Temp\disconnectedUCS.txt" 
Try {

#$htmlFile = "c:\Temp\inventoryHtml.html" 
#$htmlDCUFile = "c:\Temp\ucsInventoryWithDisconnectedUcs.htm"
#del $htmlFile -ErrorAction SilentlyContinue
#del $htmlDCUFile -ErrorAction SilentlyContinue
#$collectionVariable | ConvertTo-Html | Out-File $htmlFile

$htmlString= @'
<html>
<head>
	<meta charset="utf-8">
	<link rel="shortcut icon" type="image/ico" href="http://www.datatables.net/favicon.ico">
	<meta name="viewport" content="initial-scale=1.0, maximum-scale=2.0">

	<title>UCSM India Team Lab Inventory</title>
	<link rel="stylesheet" type="text/css" href="./media/css/jquery.dataTables.css">
	<link rel="stylesheet" type="text/css" href="./media/css/shCore.css">
	<link rel="stylesheet" type="text/css" href="./media/css/demo.css">
	<style type="text/css" class="init">

	tfoot input {
		width: 100%;
		padding: 3px;
		box-sizing: border-box;
	}

	</style>
	<script type="text/javascript" language="javascript" src="./media/js/jquery.js"></script>
	<script type="text/javascript" language="javascript" src="./media/js/jquery.dataTables.js"></script>
	<script type="text/javascript" language="javascript" src="./media/js/shCore.js"></script>
	<script type="text/javascript" language="javascript" src="./media/js/demo.js"></script>
	<script type="text/javascript" language="javascript" class="init">


$(document).ready(function() {
	// Setup - add a text input to each footer cell
	$('#example tfoot th').each( function () {
		var title = $('#example thead th').eq( $(this).index() ).text();
		$(this).html( '<input type="text" placeholder="Search '+title+'" />' );
	} );

	// DataTable
	var table = $('#example').DataTable();

	// Apply the search
	table.columns().eq( 0 ).each( function ( colIdx ) {
		$( 'input', table.column( colIdx ).footer() ).on( 'keyup change', function () {
			table
				.column( colIdx )
				.search( this.value )
				.draw();
		} );
	} );
} );

	</script>
</head>
<body class="dt-example">
	<div class="container">
		<section>
			<h1>UCSM India Team - Lab Inventory</h1>
			<table id="example" class="display" cellspacing="0" width="100%">
				<thead>
					<tr>
						<th>Component</th><th>Model</th><th>Part Nr</th><th>Serial</th><th>Version</th><th>DN</th><th>UCS</th><th>Tag</th>
					</tr>
				</thead>
				<tfoot>
					<tr>
						<th>Component</th><th>Model</th><th>Part Nr</th><th>Serial</th><th>Version</th><th>DN</th><th>UCS</th><th>Tag</th>
					</tr>
				</tfoot>
				<tbody>
					UCSINVENTORYCOLLECTIONNONE
				</tbody>
			</table>
			<h4 style="color:#CC3232">DISCONNECTEDDOMAINS</h4>
            <h4>Updated on : #GETDATE# </h4>
			<h1 style="text-align:center"><span>maintained by vaibjain@cisco.com</span></h1>
            
		</section>
	</div>
</body>
</html>
'@

$tableRows= GetHtmlTableRows -list $collectionVariable

$htmlString= $htmlString.Replace("UCSINVENTORYCOLLECTIONNONE",$tableRows)
$date=  Get-Date
$htmlString= $htmlString.Replace("#GETDATE#",$date)
if([string]::IsNullorEmpty( $disconnectedUCS))
{
    $htmlString= $htmlString.Replace("DISCONNECTEDDOMAINS","" )
}
else
{
    $htmlString= $htmlString.Replace("DISCONNECTEDDOMAINS","Disconnected UCS Domains:"+$disconnectedUCS )
}
$inventoryFile = " C:\Temp\ucsInventory.htm" 
del $inventoryFile  -ErrorAction SilentlyContinue

$htmlString | Out-File C:\Temp\ucsInventory.htm

Write-Host("UCS inventory report generated at Path: C:\Temp\ucsInventory.htm")


}
Catch {
    Write-Host ${Error}
}
Write-Host ""

