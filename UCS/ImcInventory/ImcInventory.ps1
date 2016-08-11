<#
.SYNOPSIS
	This script creates an excel sheet with the inventory details of the given standalone Cisco UCS C-series and E-series servers.

.DESCRIPTION
	This script creates an excel sheet with the inventory details of the given standalone Cisco UCS C-series and E-series servers. User need to input the 
    credentials of the Cisco IMC of these servers and the level of details that need to be fetched for each server. 

.NOTES
    Version: 1.0
    Date Modified: 4th March 2015.

#>

param(
  [parameter(Mandatory=${true})]
  [string]${ip},
  [INT]${show},
  [switch]${summ},
  [switch]${verb}
)

Write-Host ""  # must stay
#Write-Host "ucsd = $ip"
#Write-Host "show = $show"
#Write-Host "summ = $summ"
#Write-Host "verb = $verb"
#Write-Host "" # can go

if (($ip -eq "") -or ($show -lt 0) -or ($show -gt 5)) {
  Write-Host "usage: ImcInventory.ps1 -ip host1[,host2[,host3...]] -show (0..5) [-sum] [-verb]"
  Write-Host "       -ip  - a list of one or more comma separated hostnames or IP addresses"
  Write-Host "       -show - the level of detail to show"
  Write-Host "               0 = default, show all except dimms"
  Write-Host "               1 = overview of C-series or E-series server"
  Write-Host "               2 = include cpu's and memory"
  Write-Host "               3 = also hard drives and adapters"
  Write-Host "               4 = plus psu's and fans"
  Write-Host "               5 = show all dimms"
  Write-Host "       -summ  - summarize multiple identical items"
  Write-Host "       -verb  - verbose output"
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

function Add-ModelRow ([array]$arr, [string]$PartNr, [string]$Model) {

  $rec = "" | Select "PartNr","Model"

  $rec.PartNr = $PartNr
  $rec.Model = $Model

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
  $arr = Add-ModelRow -arr $arr -PartNr "UCSB-B22-M3" -Model "B22-M3"
  $arr = Add-ModelRow -arr $arr -PartNr "N20-B6620-1" -Model "B200-M1"
  $arr = Add-ModelRow -arr $arr -PartNr "N20-B6625-1" -Model "B200-M2"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSB-B200-M3" -Model "B200-M3"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSB-B200-M4" -Model "B200-M4"
  $arr = Add-ModelRow -arr $arr -PartNr "N20-B6730-1" -Model "B230-M1"
  $arr = Add-ModelRow -arr $arr -PartNr "B230-BASE-M2" -Model "B230-M2"
  $arr = Add-ModelRow -arr $arr -PartNr "N20-B6620-2" -Model "B250-M1"
  $arr = Add-ModelRow -arr $arr -PartNr "N20-B6625-2" -Model "B250-M2"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSB-EX-M4-1C" -Model "B260-M4"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSB-B420-M3" -Model "B420-M3"
  $arr = Add-ModelRow -arr $arr -PartNr "N20-B6740-2" -Model "B440-M1"
  $arr = Add-ModelRow -arr $arr -PartNr "B440-BASE-M2" -Model "B440-M2"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSB-EX-M4-1A" -Model "B460-M4"
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
  $arr = Add-ModelRow -arr $arr -PartNr "UCSC-C22-M3S" -Model "C22-M3"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSC-C22-M3L" -Model "C22-M3"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSC-C24-M3S" -Model "C24-M3"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSC-C24-M3L" -Model "C24-M3"
  $arr = Add-ModelRow -arr $arr -PartNr "R200-1120402" -Model "C200-M1"
  $arr = Add-ModelRow -arr $arr -PartNr "R200-1120402W" -Model "C200-M2"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSC-BSE-SFF-C200" -Model "C200-M2"
  $arr = Add-ModelRow -arr $arr -PartNr "R210-2121605" -Model "C210-M1"
  $arr = Add-ModelRow -arr $arr -PartNr "R210-2121605W" -Model "C210-M2"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSC-C220-M3S" -Model "C220-M3"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSC-C220-M3L" -Model "C220-M3"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSC-C220-M4S" -Model "C220-M4"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSC-C220-M4L" -Model "C220-M4"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSC-C240-M3S" -Model "C240-M3"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSC-C240-M3L" -Model "C240-M3"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSC-C240-M4S" -Model "C240-M4"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSC-C240-M4S2" -Model "C240-M4"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSC-C240-M4SX" -Model "C240-M4"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSC-C240-M4L" -Model "C240-M4"
  $arr = Add-ModelRow -arr $arr -PartNr "R250-2480805" -Model "C250-M1"
  $arr = Add-ModelRow -arr $arr -PartNr "R250-2480805W" -Model "C250-M2"
  $arr = Add-ModelRow -arr $arr -PartNr "C260-BASE-2646" -Model "C260-M2"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSC-C420-M3" -Model "C420-M3"
  $arr = Add-ModelRow -arr $arr -PartNr "R460-4640810" -Model "C460-M1"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSC-BASE-M2-C460" -Model "C460-M2"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSC-C460-M4" -Model "C460-M4"
  $arr = Add-ModelRow -arr $arr -PartNr "C880-2T-HANA-M4" -Model "C880-M4"
  $arr = Add-ModelRow -arr $arr -PartNr "C880-2T-HANA-J-M4" -Model "C880-M4"
  $arr = Add-ModelRow -arr $arr -PartNr "C880-6T-HANA-M4" -Model "C880-M4"
  $arr = Add-ModelRow -arr $arr -PartNr "C880-6T-HANA-J-M4" -Model "C880"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSC-C3160" -Model "C3160"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSC-C3260" -Model "C3260"
  $arr = Add-ModelRow -arr $arr -PartNr "N2XX-ACPCI01" -Model "P81E"
  $arr = Add-ModelRow -arr $arr -PartNr "N2XX-ABPCI01" -Model "BCM-5709"
  $arr = Add-ModelRow -arr $arr -PartNr "N2XX-ABPCI02" -Model "BCM-57711"
  $arr = Add-ModelRow -arr $arr -PartNr "N2XX-ABPCI03" -Model "BCM-5709"
  $arr = Add-ModelRow -arr $arr -PartNr "N2XX-AEPCI01" -Model "EMX-10102-CNA"
  $arr = Add-ModelRow -arr $arr -PartNr "N2XX-AEPCI03" -Model "EMX-11002-HBA"
  $arr = Add-ModelRow -arr $arr -PartNr "N2XX-AEPCI05" -Model "EMX-12002-HBA"
  $arr = Add-ModelRow -arr $arr -PartNr "N2XX-AIPCI01" -Model "INT-X520"
  $arr = Add-ModelRow -arr $arr -PartNr "N2XX-AIPCI02" -Model "INT-E1G44ETG1P20"
  $arr = Add-ModelRow -arr $arr -PartNr "N2XX-AMPCI01" -Model "MLX-CX-2-SFP"
  $arr = Add-ModelRow -arr $arr -PartNr "N2XX-AQPCI01" -Model "QLC-8152-CNA"
  $arr = Add-ModelRow -arr $arr -PartNr "N2XX-AQPCI03" -Model "QLC-2462-HBA"
  $arr = Add-ModelRow -arr $arr -PartNr "N2XX-AQPCI05" -Model "QLC-2562-HBA"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSC-PCIE-CSC-02" -Model "VIC1225"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSC-PCIE-C10T-02" -Model "VIC1225T"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSC-MLOM-CSC-02" -Model "VIC1227"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSC-PCIE-C40Q-02" -Model "VIC1285"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSC-PCIE-BSFP" -Model "BCM-57712-SFP"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSC-PCIE-BTG" -Model "BCM-57712-10T"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSC-PCIE-B3SFP" -Model "BCM-57810-SFP"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSC-PCIE-E14102" -Model "EMX-14102-CNA"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSC-PCIE-E16002" -Model "EMX-16002-HBA"
  $arr = Add-ModelRow -arr $arr -PartNr "UCSC-PCIE-ESFP" -Model "EMX-11102-CNA"
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

# Create CSV files for Part2Model / Model2Part filters
Create-ModelTable
Create-OldCpuTable

# Check for PowerTool module
if ((Get-Module | where {$_.Name -ilike "CiscoImcPS"}).Name -ine "CiscoImcPS")
{
  Write-Host "Loading Module: Cisco IMC PowerTool Module"
  Write-Host ""
  Import-Module CiscoImcPS
}

# Get UID/PWD
Try {
  Write-Host "Enter credential for CIMC(s)"
  ${imcCred} = Get-Credential
}
Catch {
  Write-Host "No credential given"
# Write-Host "Error equals: ${Error}"
  Write-Host "Exiting..."
  Write-Host ""
  exit
}
Write-Host ""

# System Configuration

$imcClasses = @("equipmentFanModule", "equipmentFan", "equipmentPsu", "computeRackUnit", "computeBoard", "processorUnit", "memoryArray", "memoryUnit", "storageLocalDisk", "adaptorUnit","firmwareRunning" )

# List of CIMC domains
Try {
  [array]$imcArray = $ip.split(" ")
  if ($imcArray.Count -eq 0) {
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

# Start clean
$xlsFile = $PSScriptRoot + "\ImcInventory.xlsx"
if (Test-Path $($xlsFile)) {
  del $xlsFile -ErrorAction SilentlyContinue  # won't succeed when open in Excel
}

# Create Excel spreadsheet
Try {
  $excelApp = New-Object -comobject Excel.Application
  $excelApp.Visible = $False
  $excelApp.sheetsInNewWorkbook = $imcArray.Count
  $workbook = $excelApp.Workbooks.Add()
}
Catch {
  Write-Host "Can't create Excel spreadsheet, is Microsoft Office installed?"
# Write-Host "Error equals: ${Error}"
  Write-Host "Exiting..."
  Write-Host ""
  exit
}

# Do a PING test on each CIMC
foreach ($imc in $imcArray) {
  $ping = new-object system.net.networkinformation.ping
  $results = $ping.send($imc)
  if ($results.Status -ne "Success") {
    Write-Host "Can't ping CIMC domain '$($imc)'"
    Write-Host "Exiting..."
    Write-Host ""
    exit
  }
}
 # Create a WorkSheet in the Excel SpreadSheet
  $sheet = 1
  $worksheet = $workbook.Worksheets.Item($sheet)
  $worksheet.Name = "Inventory"

  $col = 1
  while ($col -le 12) {
    $worksheet.Columns.Item($col).HorizontalAlignment = $hAlignLeft
    $col++
  }

  $worksheet.Columns.Item(1).columnWidth = 4
  $worksheet.Columns.Item(2).columnWidth = 4
  $worksheet.Columns.Item(3).columnWidth = 4
  $worksheet.Columns.Item(4).columnWidth = 24
  $worksheet.Columns.Item(5).columnWidth = 12
  $worksheet.Columns.Item(6).columnWidth = 12
  $worksheet.Columns.Item(7).columnWidth = 12
  $worksheet.Columns.Item(8).columnWidth = 24
  $worksheet.Columns.Item(9).columnWidth = 24
  $worksheet.Columns.Item(10).columnWidth = 24
  $worksheet.Columns.Item(11).columnWidth = 24
  $worksheet.Columns.Item(12).columnWidth = 4

# Loop through CIMC domains

$row = 0
foreach ($imc in $imcArray) {
   

  # Connect to (previous) CIMC(s)
  Disconnect-Imc

  # Login into CIMC Domain
  Write-Host "IMC Domain '$($imc)'"

  Try {
    ${imcCon} = Connect-Imc -Name ${imc} -Credential ${imcCred} -ErrorAction SilentlyContinue
    if ($imcCon -eq $null) {
      Write-Host "Can't login to: '$($imc)'"
      Write-Host "Exiting..."
      Write-Host ""
      exit
    }
  }
  Catch {
    Write-Host "Error creating a session to CIMC Domain: '$($imc)'"
    Write-Host "Error equals: ${Error}"
    Write-Host "Exiting..."
    Write-Host ""
    exit
  }

  Try {
    if ($verb) {
      Write-Host ""
    }
    $imcClasses | foreach {
      if ($verb) {
        Write-Host "Querying '$($_)'"
      }
      $classId = $($_)
      Invoke-Command -Scriptblock { & Get-ImcManagedObject -classid $_ | Export-Csv -NoType C:\Temp\$($_).csv }
    }
  }
  Catch {
    Write-Host "Error querying Class : '$($classid)'"
    Write-Host "Error equals: ${Error}"
    Write-Host "Exiting..."
    Write-Host ""
    exit
  }


  $row += 2
  $worksheet.Cells.Item($row,2) = "IMC Inventory"
  $worksheet.Cells.Item($row,5) = ${imc}
  $worksheet.Rows.Item($row).font.size = 14
  $worksheet.Rows.Item($row).font.bold = $true

  $row += 2
  $worksheet.Cells.Item($row,2) = "Components"
  $worksheet.Cells.Item($row,5) = "Model"
  $worksheet.Cells.Item($row,6) = "Quantity"
  $worksheet.Cells.Item($row,7) = "Size"
  $worksheet.Cells.Item($row,8) = "Part Nr"
  $worksheet.Cells.Item($row,9) = "Device"
  $worksheet.Cells.Item($row,10) = "Serial"
  $worksheet.Cells.Item($row,11) = "Firmware"
  $worksheet.Rows.Item($row).font.size = 11
  $worksheet.Rows.Item($row).font.bold = $true
  $worksheet.Rows.Item($row).HorizontalAlignment = $hAlignLeft

  if ($verb) {
    Write-Host ""
  }
 
  $srv = ( Import-Csv -path "C:\Temp\computeRackUnit.csv" | where { $_.Model -ne "" } | Sort-Object @{exp = {$_.Id -as [int]}} )
  if ((@($fex).count -gt 0) -or (@($srv).count -gt 0)) {
    $row += 2
    $worksheet.Cells.Item($row,2).font.bold = $true
    $worksheet.Cells.Item($row,2) = "Rack Servers"
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

    if (($show -eq 0) -or ($show -gt 1)) {
      $row++
    }
    $row++
    $worksheet.Cells.Item($row,3).font.bold = $true
    $worksheet.Cells.Item($row,3) = "Server $($sv.Id)"
    $svModel = $p2m.Model
    if($p2m.Model -eq $null -or $p2m.Model -eq "")
    {
        $svModel = $sv.Name
    }
    $worksheet.Cells.Item($row,5) = $($svModel)
    $worksheet.Cells.Item($row,8) = $($sv.Model)
    $worksheet.Cells.Item($row,10) = $($sv.Serial) -replace 'N/A',''
    $worksheet.Cells.Item($row,11) = $fws.Version

    if (($show -eq 0) -or ($show -ge 2)) {
      $cpu = ( Import-Csv -path "C:\Temp\processorUnit.csv" | where { $_.Dn -like "$($sv.Dn)*" } | where { $_.Model -ne "" } | Sort-Object @{exp = {$_.Id -as [int]}} )
      foreach ($pr in $cpu) {
        if ($verb) {
          Write-Host "pr: $($pr.Dn)"
        }

#       $c2p = ( Import-Csv -path ".\cpu2partnr.csv" | where { $_.Description -like "$($pr.Model)*" } )

        $m = Get-ModelCPU($pr.Model)
        $p = Get-PartNrCPU($m)

        $row++
        $worksheet.Cells.Item($row,4) = "Processor $($pr.Id)"
        $worksheet.Cells.Item($row,5) = $m
        $worksheet.Cells.Item($row,8) = $p
        $worksheet.Cells.Item($row,10) = $($pr.Serial) -replace 'N/A',''

        if ($summ) {
          $worksheet.Cells.Item($row,4) = "Processors"
          $worksheet.Cells.Item($row,6) = @($cpu).count
          $worksheet.Cells.Item($row,10) = ""
          break
        }
      }
    }

    if (($show -eq 0) -or ($show -ge 2)) {
      $mem = ( Import-Csv -path "C:\Temp\memoryArray.csv" | where { $_.Dn -like "$($sv.Dn)*" } | Sort-Object @{exp = {$_.Id -as [int]}} ) # careful: Model is empty

      [int]$cap = 0
      foreach ($ma in $mem) {
        if ($verb) {
          Write-Host "ma: $($ma.Dn)"
        }
        $cap += (0 + $ma.CurrCapacity)
      }
      $cap /= 1024

      $dim = ( Import-Csv -path "C:\Temp\memoryUnit.csv" | where { $_.Dn -like "$($sv.Dn)*" } | where { $_.Model -ne "" } | where { $_.Id -eq "1" } )

      $row++
      $worksheet.Cells.Item($row,4) = "Memory"
      $worksheet.Cells.Item($row,7) = "$($cap) GB"
      $worksheet.Cells.Item($row,9) = $dim.Model
    }

    if (($show -ge 5) -and (-not $summ)) {
      $dim = ( Import-Csv -path "C:\Temp\memoryUnit.csv" | where { $_.Dn -like "$($sv.Dn)*" } | where { $_.Model -ne "" } | Sort-Object @{exp = {$_.Id -as [int]}} )
      foreach ($mm in $dim) {
        if ($verb) {
          Write-Host "mm: $($mm.Dn)"
        }

        [int]$cap = 0 + $mm.Capacity
        $cap /= 1024

        $row++
        $worksheet.Cells.Item($row,4) = "Module $($mm.Id)"
        $worksheet.Cells.Item($row,7) = "$($cap) GB"
        $worksheet.Cells.Item($row,9) = $($mm.Model)
        $worksheet.Cells.Item($row,10) = $($mm.Serial) -replace 'N/A',''
      }
    }

    if (($show -eq 0) -or ($show -ge 3)) {
      $hdd = ( Import-Csv -path "C:\Temp\storageLocalDisk.csv" | where { $_.Dn -like "$($sv.Dn)*" } | where { $_.Model -ne "" } | Sort-Object @{exp = {$_.Id -as [int]}} )
      foreach ($hd in $hdd) {
        if ($verb) {
          Write-Host "hd: $($hd.Dn)"
        }

        # old disks (73/146 GB) report too low size (like 70136 MB), newer disks report correct size but in kB
        $size = 0 
        $temp = [long]::TryParse($hd.CoercedSize.Replace("MB","").Trim() , [ref] $size)

        [double]$sz = 0.0 + $size
        [int]$gb = 0
        if ($sz -ge (1024)) {
          $sz /= (1024);
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

        $row++
        $worksheet.Cells.Item($row,4) = "Hard Drive $($hd.Id)"
        $worksheet.Cells.Item($row,7) = "$($gb) GB"
        $worksheet.Cells.Item($row,9) = $($hd.ProductId)
        $worksheet.Cells.Item($row,10) = $($hd.DriveSerialNumber) -replace 'N/A',''

        if ($summ) {
          $worksheet.Cells.Item($row,4) = "Hard Drives"
          $worksheet.Cells.Item($row,6) = @($hdd).count
          $worksheet.Cells.Item($row,10) = ""
          break
        }
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

        $row++
        $worksheet.Cells.Item($row,4) = "I/O Adaptor $($io.Id)"
        $worksheet.Cells.Item($row,5) = $($p2m.Model)
        $worksheet.Cells.Item($row,8) = $($p2m.PartNr)
        $worksheet.Cells.Item($row,10) = $($io.Serial) -replace 'N/A',''
        $worksheet.Cells.Item($row,11) = $fws.Version

        if ($summ) {
          $worksheet.Cells.Item($row,4) = "I/O Adaptors"
          $worksheet.Cells.Item($row,6) = @($ioa).Count
          $worksheet.Cells.Item($row,10) = ""
          break
        }
      }
    }

    if (($show -eq 0) -or ($show -ge 4)) {
      $psu = ( Import-Csv -path "C:\Temp\equipmentPsu.csv" | where { $_.Dn -like "$($sv.Dn)*" } | where { $_.Model -ne "" } | Sort-Object @{exp = {$_.Id -as [int]}} )
      foreach ($ps in $psu) {
        if ($verb) {
          Write-Host "ps: $($ps.Dn)"
        }

        #$p2m = ( Import-Csv -path "C:\Temp\Part2Model.csv" | where { $_.PartNr -like "$($ps.Model)*" } )

        $row++
        $worksheet.Cells.Item($row,4) = "Power Supply $($ps.Id)"
        $worksheet.Cells.Item($row,5) = $($ps.Model)
        #$worksheet.Cells.Item($row,8) = $($p2m.PartNr)
        $worksheet.Cells.Item($row,10) = $($ps.Serial) -replace 'N/A',''

        if ($summ) {
          $worksheet.Cells.Item($row,4) = "Power Supplies"
          $worksheet.Cells.Item($row,6) = @($psu).count
          $worksheet.Cells.Item($row,10) = ""
          break
        }
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

#         # model is empty for rackmount fans and fan-modules
#         $p2m = ( Import-Csv -path "C:\Temp\Part2Model.csv" | where { $_.PartNr -like "$($fm.Model)*" } )

          $row++
          $worksheet.Cells.Item($row,4) = "Cooling Fan $($fm.Id)"
#         $worksheet.Cells.Item($row,5) = $($p2m.Model)
#         $worksheet.Cells.Item($row,8) = $($p2m.PartNr)
          $worksheet.Cells.Item($row,10) = $($fm.Serial) -replace 'N/A',''

          if ($summ) {
            $worksheet.Cells.Item($row,4) = "Cooling Fans"
            $worksheet.Cells.Item($row,6) = @($fan).count
            $worksheet.Cells.Item($row,10) = ""
            break
          }
        }

      }
      else { # no fan modules

        foreach ($cf in $fan) {
          if ($verb) {
            Write-Host "cf: $($cf.Dn)"
          }

#         $p2m = ( Import-Csv -path "C:\Temp\Part2Model.csv" | where { $_.PartNr -like "$($cf.Model)*" } )

          $row++
          $worksheet.Cells.Item($row,4) = "Cooling Fan $($cf.Id)"
#         $worksheet.Cells.Item($row,5) = $($p2m.Model)
#         $worksheet.Cells.Item($row,8) = $($p2m.PartNr)
          $worksheet.Cells.Item($row,10) = $($cf.Serial) -replace 'N/A',''

          if ($summ) {
            $worksheet.Cells.Item($row,4) = "Cooling Fans"
            $worksheet.Cells.Item($row,6) = @($fan).count
            $worksheet.Cells.Item($row,10) = ""
            break
          }
        }

      } # end if module or fan
    }

  }

  if ($verb) {
    Write-Host ""  
  }

} # end loop $imc

Try {
  del $xlsFile -ErrorAction SilentlyContinue
  $workbook.SaveAs($xlsFile)
}
Catch {
  Write-Host "Spreadsheet could not be saved (still open in Excel ??)"
  Write-Host ""
}
$excelApp.quit()

# Logout from CIMC
Disconnect-Imc
Write-Host "Logout..."
Write-Host ""

