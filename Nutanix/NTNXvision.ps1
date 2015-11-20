<#
.SYNOPSIS
	Retrieves Nutanix cluster information to automatically generate a Visio diagram of the infrastructure.
.DESCRIPTION

.PARAMETER NTNXCluster 
	A cluster name or IP to connect to the Nutanix Cluster

.EXAMPLE
	Connect to the cluster "myntnxclu.lab.local"
	./NTNXvision.ps1 myntnxclu.lab.local
.EXAMPLE 
	Launch the script
	./NTNXvision.ps1
.NOTES
	You don't have to specify any cluster name or username as the script will ask for.

#>


Param ($NTNXCluster=$FALSE)

if ( (Get-PSSnapin -Name NutanixCmdletsPSSnapin -ErrorAction SilentlyContinue) -eq $null )
{
Add-PsSnapin NutanixCmdletsPSSnapin
}

# The name of the Visio Gabarit used to draw the diagram with the right stencil
# It must be located with this script, at the same directory level !
$shpFile = "NTNX_Shape.vssx"

# In case of a missing argument, ask for the NTNXcluster name/ip to connect
if ($NTNXCluster -eq $FALSE) { $NTNXCluster = Read-Host "Please enter the IP or name of the Nutanix Cluster " }


# A generic function to add an object into a visio shape
function add-visioobject ($mastObj, $item)
{
 		Write-Host "Adding $item"
		# Drop the selected stencil on the active page, with the coordinates x, y
  		$shpObj = $pagObj.Drop($mastObj, $x, $y)
		# Enter text for the object
		$shpObj.Text = $item
		#Return the visioobject to be used
		return $shpObj
 }

# Create an instance of Visio and create a document based on the Basic Diagram template.
$AppVisio = New-Object -ComObject Visio.Application
$docsObj = $AppVisio.Documents
#$DocObj = $docsObj.Add("Basic Diagram.vst")
$DocObj = $docsObj.Add("")

# Set the active page of the document to page 1
$pagsObj = $AppVisio.ActiveDocument.Pages
$pagObj = $pagsObj.Item(1)

# Connect to the NTNX Cluster
$NTNXCluster = Connect-NTNXCluster $NTNXCluster -AcceptInvalidSSLCerts 

# Load a set of stencils and select one to drop
$stnPath = (Get-Location).path
$stnObj = $AppVisio.Documents.Add($stnPath+"\"+$shpFile)
$HostNXObj = $stnObj.Masters.Item("NX")
$Host7Obj = $stnObj.Masters.Item("XC730")
$Host6Obj = $stnObj.Masters.Item("XC630")
$VMWObj = $stnObj.Masters.Item("VM Windows")
$VMLObj = $stnObj.Masters.Item("VM Linux")
$VMObj =  $stnObj.Masters.Item("VM")

# Load the default container shape
$stencil = $AppVisio.Documents.OpenEx($AppVisio.GetBuiltInStencilFile(2,1),64)
$container = $stencil.Masters.ItemFromID(2)

# Test if the Cluster exist
If ((Get-NTNXCluster) -ne $Null){
	# Get all the NTNX object required
	$Cluster = (Get-NTNXCluster)
	$NTNXHosts = (Get-NTNXHost)
	$NTNXVMs = (Get-NTNXVM | where {$_.vmName -notmatch "-CVM"})
	$NTNXSPs = (Get-NTNXStoragePool)
	$NTNXContainers = (Get-NTNXContainer)
	
	# Set Visio to its initial position
	$x = 0
	$y = 0
	
	# Create the container for the Cluster
	$boxCluster = $pagObj.Drop($container, $x ,$y)
	$boxCluster.Text = $Cluster.name

	# Add each of the host of the cluster into the container
	ForEach ($NTNXHost in $NTNXHosts)
	{
		if ($NTNXHost.blockModelName.contains("730") -eq $True)
		{
			$Object1 = add-visioobject $Host7Obj $NTNXHost.name
		}elseif ($NTNXHost.blockModelName.contains("630") -eq $True)
		{
			$Object1 = add-visioobject $Host6Obj $NTNXHost.name
		}else
		{
			$Object1 = add-visioobject $HostNXObj $NTNXHost.name
		}
		$boxCluster.containerProperties.AddMember($Object1,1)
		$hpv = $pagObj.DrawRectangle($x-0.7, $y+0.2, $x+0.7, $y+0.6)
		$hpv.CellsU("LinePattern").FormulaU = "0"
		if ($NTNXHost.hypervisorType.contains("kHyperv") -eq $True)
		{
			$hpv.Text = "Hyper-V"
			$hpv.CellsU("FillForegnd").FormulaU = "=RGB(75, 172, 198)"
		}elseif ($NTNXHost.hypervisorType.contains("kVMware") -eq $True)
		{
			$hpv.Text = "VMware"
			$hpv.CellsU("FillForegnd").FormulaU = "=RGB(255,192,0)"
		}elseif ($NTNXHost.hypervisorType.contains("KVM ") -eq $True)
		{
			$hpv.Text = "KVM"
			$hpv.CellsU("FillForegnd").FormulaU = "=RGB(157, 187, 97)"
		}else
		{
			$hpv.Text = "Acropolis"
			$hpv.CellsU("FillForegnd").FormulaU = "=RGB(192, 80, 70)"
		}
		$x = 0
		$y += 2.50
	}
	$boxCluster.resize(2,60,33)
	$y = 0
	$x = 1.6

	# Add each of the NTNXContainer of the cluster into the sheet (a rectangle)
	ForEach ($NTNXContainer in $NTNXContainers)
	{
		# Don't use a VisioContainer here because it breaks the layout
		$Cont = $pagObj.DrawRectangle($x, $y-1, $x+2, $y+(2.5*$NTNXHosts.count)-1.3)
		$Cont.CellsU("LinePattern").FormulaU = "16"
		$Cont.Text = $NTNXContainer.name +"
Max Capacity : " + [math]::truncate($NTNXContainer.maxCapacity / 1GB) + " GB
Usable Capacity : " + [math]::truncate(($NTNXContainer.maxCapacity/$NTNXContainer.replicationFactor) / 1GB) + " GB"
		$x += 2
	}
	
	# Add each of the VM of the cluster into a container by host
	ForEach ($NTNXHost in $NTNXHosts)
	{
		$x = 0.6 + (2*$NTNXContainer.count)
		$box = $pagObj.Drop($container, $x+$x ,$y)
		$box.Text = $NTNXHost.name
		ForEach ($NTNXVM in $NTNXVMs)
		{	
			# Test if the VM is hosted on the host
			if ($NTNXVM.hostName -eq $NTNXHost.name)
			{
				$x += 1.50
				# Check the OS type of the VM to assign a different logo
				$os = $NTNXVM.guestOperatingSystem
				If ($os.contains("Windows") -eq $True)
				{
					$Object2 = add-visioobject $VMWObj $NTNXVM.vmName
				}
				Elseif($os.contains("Linux") -eq $True)
				{
					$Object2 = add-visioobject $VMLObj $NTNXVM.vmName
				}
				Else
				{
					$Object2 = add-visioobject $VMObj $NTNXVM.vmName
				}
				$Object2.resize(1,50,33)
				# Add the VM into the right container
				$box.containerProperties.AddMember($Object2,1)
				$Object1 = $Object2
			}
		}
		$y += 2.50
	}
}

# Resize to fit page
$pagObj.ResizeToFitContents()