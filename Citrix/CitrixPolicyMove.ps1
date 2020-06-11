# Script for Moving Farm Policies into a GPO
# From http://www.danieletosatto.com/2010/08/02/how-to-move-citrix-policies-from-farm-to-a-gpo/

Add-PSSnapIn Citrix.Common.GroupPolicy -ErrorAction SilentlyContinue

function MoveCitrixPolicies ($sourcePath, $targetPath)
{
  # Save priority lists - these are not preserved on transfer
  $CP = Get-ChildItem $sourcePath\Computer | Select Name, Priority | Sort Priority
  $UP = Get-ChildItem $sourcePath\User | Select Name, Priority | Sort Priority

  # Move all policies
  Get-Item $sourcePath\Computer\* -Exclude "Unfiltered" | ForEach { Move-Item $_.PSPath $targetPath\Computer }
  Get-Item $sourcePath\User\* -Exclude "Unfiltered" | ForEach { Move-Item $_.PSPath $targetPath\User }
  Copy-Item $sourcePath\Computer\Unfiltered $targetPath\Computer\Unfiltered
  Copy-Item $sourcePath\User\Unfiltered $targetPath\User\Unfiltered
  Clear-Item $sourcePath\Computer\Unfiltered
  Clear-Item $sourcePath\User\Unfiltered 

  # Fix priorities
  foreach ( $p in $CP)
  {
    Set-ItemProperty -LiteralPath $targetPath\Computer\$($p.Name) -Name Priority -Value $p.Priority
  }

  foreach ( $p in $UP)
  {
    Set-ItemProperty -LiteralPath $targetPath\User\$($p.Name) -Name Priority -Value $p.Priority
  }
}

# Mount POlicies
New-PSDrive -PSProvider CitrixGroupPolicy -Name SourceGPO -Root \ -DomainGPO "CitrixGPONewFarm"
New-PSDrive -PSProvider CitrixGroupPOlicy -Name TargetGPO -Root \ -DomainGpo "Citrix PolicyTest" 

MoveCitrixPolicies "SourceGPO:" "TargetGPO:"
Remove-PSDrive SourceGPO
Remove-PSDrive TargetGPO


# Another example to set policies priorities:
#set-itemproperty .\policyname -name Priority -value 2