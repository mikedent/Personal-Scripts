Function Upgrade-Datastore{
<#
	.Synopsis
	At its core, this script takes a target datastore, migrates VMs away from the datastore, deletes the datastore, and recreates the datastore as VMFS 5
	
	.Description
	User supplies a VMFS Datastore which will be upgraded to VMFS5
	Migrates VMs to other datastores either supplied by the $moveto variable, or the custom algorithm built into the script
	After all migrations have completed, checks to see if any VMs are still located on the Datastore(because of a migration failure), if VMs are left, the script exits
	Once confirmed that no VMs are left, Deletes the datastore, then recreates the datastore as VMFS 5.
	
	Migration Selection Process=
	
	To Start this does not apply if using $MoveTo
	
	First Filter: we take all the datastore and compare them to the exlclusions, what we're left with possible the ossible datastores where the VM could be Storage vMotioned to
	
	Second Filter: It will ignore datastores if they have been used in the previous $excludeprevious attempts
	
	Third Filter: It filters down this list even further per VM. This confirms that the datastore has free space which is 25% more than UsedSpace of the VM.
	
	From this filtered down list, it picks a random datastore for the VM to be Migrated to
	
	The reason for all of this, is so one Datastore is not picked over and over and the Storage vMotion max out the capacity and freeze the drive.
	
	
	Unaccounted Variables/Potential Future Updates
	
	This script does currently take into account:
	1. Other files, like ISOs, which reside on the datastore. They might be deleted
	2. VMs with multiple vmdks located in different locations. It will migrate all vmdks to the chosen datastore
	
	.Parameter Upgradestore
	This is the datastore that is selected to be upgraded
	
	.Parameter Server
	The vCenter server the script connects where the datastore is located. 
	This is included for safety, in case your native powershell/powercli session is connected to multiple vCenters

    .Paremter User/Password
    The Credentials to use for running the script
	
	.Parameter Moveto
	Used if you have a specific datastore you want the VMs moved to while $Upgradestore is being deleted and recreated, not a required variable. 
	If this is Not used, the script will decide where to migrate VMs
	
	.Parameter MaxConcurrent
	If Not Using $MoveTo, the maximum concurrent storage migrations the script will allow. 
	This is used as a safety in case $upgradestore has A Lot of VMs and several don't get assigned to migrate to the same datastore and potentially max out UsedSpace on the datastore. 
	There are several other checks in an attempt to prevent this.
	
	.Parameter Exclusions
	If you are Not using the MoveTo variable, use this variable to define Datastore you do Not want VMs migrated to. 
	For example, datastores you might define here could be host local storage, storage for swap, storage for backups...etc
	
	.Parameter MoveBack
	After everything is said and done....do you want to move the VMs back to their original datastore
	
	.Parameter ExcludePrevious[INT]
	This will exclude the previous $excludeprevious Datastores when deciding where to migrate the next VM
	
	.Parameter Confirm
	 
	 By default, it will prompt to confirm before deleting and creating the datastore, if you don't want this set $confirm to $false
	 
	 .Parameter SamplePeriod
	 
	 The time between samples, in order to determine rate a which storage vMotions are progressing
	
	.Example
	
	upgrade-datastore -datastore VolumeA -moveto VolumeB -moveback -server vcenter.vnoob.local
	
	This example will queue up all vm's and templates on VolumeA to be moved to VolumeB. Since -moveto was chosen it will not take into account the datastore selection process or the maxconcurrent process.
	
	.Example
	
	$exclusions="VolumeB", "VolumeC"
	
	C:\PS>upgrade-datstore -datastore VolumeA -server vcenter.vnoob.local -Exclusions $exclusions -maxconcurrent 3
	
	In this example the script will decide where to move the VMs and Templates from VolumeA, however it will not move anything to VolumeB or VolumeC. It will also only move 3 at a time
	
	.Example
	
	$exclusions="VolumeB", "VolumeC"
	
	C:\PS>upgrade-datstore -datastore VolumeA -server vcenter.vnoob.local -Exclusions $exclusions -maxconcurrent 3 -excludeprevious 2
	
	Same previous example except this time along with excluding VolumeB and VolumeC, it will also exclude the last two datastores selected in the Storage vMotion Process
	This is another step to try to prevent the Storage vMotions from accidentally filling a datastore.
	
	.Example
	
	upgrade-datstore -datastore VolumeA -server vcenter.vnoob.local -maxconcurrent 3 -sampleperiod 180
	
	Will completely decide where to move VMs and Templates. Once 3 are in process it will Take a sample, Wait the $sampleperiod, then take another sample. From this it will make educated guess when one of those 3 will be done first, and wait-task on that task. After that task has finished it will proceed.
	
	.Link
	www.vnoob.com
	
	
	.Notes	
	
	It should be noted...When using -moveto... $exclusions, $maxconcurrent, $sampleperiod, $excludeprevious are all not taken into account. 
	
	The reason for this is when using -moveto you are deciding that you have investigated the destination(moveto) datastore, and that all VMs and Templates will be able to move there. 

====================================================================
	Author:
	Conrad Ramos <conrad@vnoob.com> http://www.vnoob.com/

	Date:			2012-2-21
	Revision: 		1.0
	
	Disclaimer:
	This can and will delete your datastore if you are not careful. 
	I have taken many precautions in the script to try to prevent accidentally deleting things you may want,
	but at the end of the day it is your responsibility to make sure you do not delete your stuff. Pretty much, 
	I am saying I am not responsible for how you use this script.
	
	
====================================================================


#>


param([Parameter(mandatory=$true, HelpMessage="Enter the name of the datastore you would like to upgrade.")]$upgradestore, 
	[Parameter(mandatory=$true, HelpMessage="Enter the name of the vCenter Server you want to connect to.")]$server,$user,$pass,
	[array]$exclusions, $maxconcurrent="4", $moveto=$null, [switch]$moveback, $confirm=$true, [int]$excludeprevious=2, $sampleperiod=300)





Try{
Disconnect-VIServer -Server * -Force -Confirm:$false -ErrorAction SilentlyContinue}
Catch{}
Connect-VIServer $server -User $user -Password $pass -ea silentlycontinue -ErrorVariable +err
IF($err.count -gt 0)
{Write-Warning "Unable to connect to $server" ;return}

#Datastore Prep
$datastore=Get-Datastore $upgradestore -ea silentlycontinue -ErrorVariable +err
IF($err.count -gt 0)
{Write-Warning "Cannot Locate Datastore $upgradestore" ;return}

$datastores=get-Datastore
$alldathost=$datastore|Get-VMHost
$datHost=$datastore|get-VMHost|select -First 1
$canonical= $datastore|Get-ScsiLun|select -ExpandProperty canonicalname|Get-Unique
$datastoreid=$datastore.id

$storename=(get-datastore $upgradestore).name
IF(($exclusions|?{$_ -like $storename}) -eq $null){$exclusions+=$upgradestore}

#$Destinations is a combination of all the datastores Minus the ones listed in the $exceptions variable. This will be the pool the script draws on to decide where to migrate the VMs to
$destinations=compare-object $datastores $exclusions|select -expandproperty inputobject

IF(($destinations.count -lt $excludeprevious))
{Write-Warning "The sum of the available datastores subtracted by the '-exclusions' must be `
greater than '-excludeprevious' in order for Storage vMotions to work correctly" ;return}

$refresh=$destinations

New-Customattribute -name Unregistered -targettype virtualmachine -ea silentlycontinue |Out-Null
New-Customattribute -name Template -targettype virtualmachine -ea silentlycontinue|Out-Null
$err=$null





New-PSDrive -Name TgtDS -Location $Datastore -PSProvider VimDatastore -Root '\' | Out-Null
#Template Prep
Write-Output "Checking for and Registering Unregistered Templates"
$templates=get-template|?{$_.datastoreidlist -like $datastoreid}
$registeredtemps = @{}
  #$templates | %{$_.Extensiondata.LayoutEx.File | where {$_.Name -like "*.vmtx"} | %{$registeredtemps.Add($_.Name,$true)}}
 $templates|%{ Get-ChildItem -Path TgtDS:$_ -Recurse|?{$_.name -like "*.vmtx"}|%{$registeredtemps.add($_.name,$true)}}
   # Set up Search for .VMTX Files in Datastore
  
  $unregisteredtemps = @(Get-ChildItem -Path TgtDS: -Recurse | `
    where {$_.FolderPath -notmatch ".snapshot" -and ($_.name -like "*.vmtx") -and !$registeredtemps.ContainsKey($_.Name)})
  
 
   #Register all .vmtx Files as Templatess on the datastore
   foreach($VMTXFile in $unregisteredtemps) {

      $temp=New-template -templatefilepath $VMTXFile.DatastoreFullPath -VMHost $datHost
	  $temp |Set-Annotation -CustomAttribute Unregistered -Value PreviouslyUnregistered
}

$templates=get-template|?{$_.datastoreidlist -like $datastoreid}
IF ($templates -ne $null)
	{
	Write-Output "Settings Templates to VMs"
	$templates |Set-Annotation -CustomAttribute Template -Value PreviouslyTemplate
	$templates|set-template -tovm|out-null
	}

	
#VM Prep
$vms=$datastore|Get-VM



#Unregistered VM Prep
 # Collect .vmx paths of registered VMs on the datastore
 Write-Output "Checking for and Registering Unregistered VMs"
  $registered = @{}
  #$vms | %{$_.Extensiondata.LayoutEx.File | where {$_.Name -like "*.vmx"} | %{$registered.Add($_.Name,$true)}}
 $vms|%{ Get-ChildItem -Path TgtDS:$_ -Recurse|?{$_.name -like "*.vmx"}|%{$registered.add($_.name,$true)}}
   # Set up Search for .VMX Files in Datastore
  
  $unregistered = @(Get-ChildItem -Path TgtDS: -Recurse |where {$_.FolderPath -notmatch ".snapshot" -and $_.Name -like "*.vmx" -and !$registered.ContainsKey($_.Name)})
  
 
   #Register all .vmx Files as VMs on the datastore
   foreach($VMXFile in $unregistered) {

      $unvm=New-VM -VMFilePath $VMXFile.DatastoreFullPath -VMHost $datHost
	  $unvm|Set-Annotation -CustomAttribute Unregistered -Value PreviouslyUnregistered
	  
}
Remove-PSDrive -Name TgtDS

$vms=$datastore|Get-VM
$count=$vms.count


[array]$tasktrackers=@()

#MoveTo given a value will just queue up all the VMs to move to the moveto datastore
IF($moveto -ne $null)
{
	$moveto=Get-Datastore $moveto -ea silentlycontinue -ErrorVariable +err
	IF($err.count -gt 0)
	{Write-Warning "Cannot Locate Datastore $upgradestore" ;return}

FOREACH($VM in $vms)
	{
	$vmname=$null
	
	$vmmove= ""| select -Property name, taskid
	Write-Output "Migrating $vm to $moveto"
	move-VM -VM $vm -Datastore $moveto -RunAsync
	$vmmove.name=$vm.name
	$vmname=$VM.name
	$vmmove.taskid=(get-task -status running|?{((get-View $_).info.entityname -like "*$vmname*") -AND ($_.description -like "*relocate*")}|get-view).info.key
	$tasktrackers+=$vmmove
	}
	
}

#If a moveto value is not used, this section will go through and select which datastores to use on a per VM basis.
Else
{ 
	[int]$i=0
	FOREACH($VM in $vms)
	{
	$destinations=$refresh
	
	$wait=$null
	$vmname=$null
	$vmmove= ""| select -Property name, taskid, destination
		#Test to see if there are already $maxconcurrent Storage vMotions in progress. If there is it will check to see if there are any over 85% complete,  	
		#and wait on the one furthest along to complete. IF none are over 85% it will wait on the the one with the smallest amount of used space, before continuing
		IF((get-task -status running|?{($_.description -like "*relocate*")}).count -ge $maxconcurrent)
		{
		
		$wait=get-task -Status running|?{($_.percentcomplete -gt "85") -and ($_.description -like "*relocate*")}|sort percentcomplete -desc|select -First 1
		If($wait -ne $null)
			{
			Write-Output "Percent Complete"
			$viewwait=$wait|Get-View
			$vmname=$viewwait.info.entityname
			Write-Output "Waiting for $vmname to Migrate"
			wait-Task -Task $wait
			}
		Else
			{
			[array]$judges=@()
			Write-Output "Taking Sample 1"
			
			#This next section I take a sample, wait some time, take another sample. From this then we estimate when the next Storage Migration will end. 
			#It will do this by taking the how far the Storage Migration has progressed, how close it is to 100%. Since this was done over a time rate, it essentialy finds it rate of progression/completion.
			
			ForEach($tasktracker in $tasktrackers)
			{
			$judgetask=$null
			$waittask=""| select taskid, percent1, percent2, difference, ratio
			$id=$tasktracker.taskid
			$judgetask=get-task -Status Running |?{(($_.description -like "*relocate*") -and (get-view $_).info.key -like "*$id*")}
			IF($judgetask -ne $null){
			$waittask.taskid=$id
			$waittask.percent1=$judgetask.percentcomplete
			$judges+=$waittask
			}
			}
			Start-Sleep -Seconds $sampleperiod
			
			Write-Output "Taking Sample 2"
			FOREach($judge in $judges)
			{
			$id=$judge.taskid
			$smallratio=$null
			$judgetask=$null
			$judgetask=get-task -Status Running |?{((get-View $_).info.entityname -like "*$vmname*") -AND ($_.description -like "*relocate*") -and (get-view $_).info.key -like "*$id*"}
			$judge.percent2=$judgetask.percentcomplete
			$judge.difference = $judge.percent2 - $judge.percent1
			
			try{$judge.ratio= (100-$judge.percent2)/($judge.difference)}
			Catch {}
			}
			
			IF(($judges|?{(($_.percent2 -eq "100") -or ($_.difference -lt 0))}) -eq $null)
			{
			#$judges|sort ratio|ft -auto
			$smallratio=($judges|?{$_.difference -ne 0}|sort ratio|select -First 1)
			$id=$smallratio.taskid
			$waitjudge=get-task -Status Running |?{(($_.description -like "*relocate*") -and ((get-view $_).info.key -like "*$id*"))}
			#$waitjudge
			$judgename=(get-view $waitjudge).info.entityname
			Write-Output "Waiting for $judgename to Migrate"
			Wait-Task -task $waitjudge
			}
			Else{Write-Output "A Task Finished during the Sample Period, Moving On"}
			}
		}
		
		#Filters the possible datastores down even further to exclude previously used Datastores up to	$excludeprevious, 
		#then to#datastores that have 25% more free space than the VM requires 
	
	IF(($i -le $excludeprevious) -and ($i -gt 0))
	{
		$previous=$tasktrackers[($i-1)..0]|%{$_.destination}
		$destinations=compare-object $destinations $previous|select -expandproperty inputobject
	}
	ElseIF($i -gt $excludeprevious)	
	{
		$previous=$tasktrackers[($i-1)..($i-$excludeprevious)]|%{$_.destination}
		$destinations=compare-object $destinations $previous|select -expandproperty inputobject
		}
	
	$destinations=get-datastore $destinations
	
	$moveto=$destinations|?{($_.freespacemb / 1KB) -gt (($vm.usedspacegb)*1.25)}|get-random
	If($moveto -eq $null){Write-Warning "No more Datastores match the criteria for Storage vMotion" ;return}
	Write-Output "Migrating $vm to $moveto"
	
	move-VM -VM $vm -Datastore $moveto -RunAsync |Out-Null	



	$vmmove.name=$vm.name
	$vmname=$VM.name
	$vmmove.taskid=(get-task -status running|?{((get-View $_).info.entityname -like "$vmname") -AND ($_.description -like "*relocate*")}|get-view).info.key
	$vmmove.destination=$moveto
	$tasktrackers+=$vmmove

	[int]$i=$i+1
	}
}

#This section takes all the tasks that have been created and confirms that they have all finished before moving on to the next step
ForEach($tasktracker in $tasktrackers)
{
$vmname=$null
$task=$null
$vmname=$tasktracker.name
$id=$tasktracker.taskid
$task=get-task -Status Running |?{(((get-View $_).info.entityname -like "$vmname") -AND ($_.description -like "*relocate*") -and ((get-view $_).info.key -like "*$id*"))}
	If ($task -ne $null)
	{$vmname=$tasktracker.name
	Write-Output "Waiting for $vmname to finish Migrating"
		Wait-Task $task
		
	}
}



# At this point if ANY VMs are left on the datastore, the script exits....
IF(((Get-Datastore $datastore|Get-VM) -ne $null) -or ((get-template|?{$_.datastoreidlist -like $datastoreid}) -ne $null))
{
Write-Warning "One of the VMs or Templates was not able to be moved to another datastore"
return
}

#Delete Datastore
Write-Output "Deleting Volume $Upgradestore"
$delete=(remove-datastore -datastore $datastore -vmhost $dathost -runasync -confirm:$confirm)
Write-Output "Waiting for $UpgradeStore to be deleted"
$delete|Wait-Task


Start-Sleep -Seconds 20

#Create Datastore
Write-Output "Recreating Volume $datastore"
$new=(new-datastore -name $Storename -host $dathost -vmfs -path $canonical -filesystemversion 5 -confirm:$confirm)



Write-Output "Rescanning Storage"
Get-VMHostStorage -vmhost $alldathost -RescanVmfs |Out-Null

Start-Sleep 40

#If user wants to move VMs back after upgrade
IF($moveback)
{

Write-Output "Moving VMs back to their original Datastore"
move-VM -VM $vms -Datastore $upgradestore -RunAsync |Out-Null
	
}
ForEach($template in $templates){
$vmname=$template.name
$temptask=get-task -Status Running |?{(((get-View $_).info.entityname -like "$vmname") -AND ($_.description -like "*relocate*"))}
If($temptask -ne $null)
{wait-task $temptask}
get-vm $template|set-vm -totemplate -confirm:$false|out-null
}

$unregister=$vms |get-annotation -customattribute Unregistered|?{$_.value -eq "PreviouslyUnregistered"}|select -expand annotatedentity
IF($unregister -gt $null)
{Write-Output "Unregistering VMs and Templates which were previously unregistered"
Remove-Inventory $unregister -Confirm:$false
}

Remove-CustomAttribute -CustomAttribute Unregistered -Confirm:$false
Remove-CustomAttribute -CustomAttribute Template -Confirm:$false

}

