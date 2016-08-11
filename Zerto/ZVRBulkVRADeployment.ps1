###########################################################################
# Start of the script - Description, Requirements & Legal Disclaimer
###########################################################################
# https://virtuallysober.com/2016/02/11/introduction-to-powershell-and-zerto-rest-api-scripting/
################################################
# Description:
# This script automates the deployment of VRAs for the hosts in the specified CSV file using PowerCLI and the Zerto API to complete the process.
################################################ 
# Requirements:
# - ZVM ServerName, Username and password with permission to access the API of the ZVM
# - vCenter ServerName, Username and password to establish as session using PowerCLI to the vCenter
# - ESXi root user and password for deploying the VRA
# - Network access to the ZVM and vCenter, use the target site ZVM for storage info to be populated
# - Access permission to write in and create (or create it manually and ensure the user has permission to write within)the directory specified for logging
# - VMware PowerCLI, any version, installed on the host running the script
# - Run PowerShell as administrator with command "Set-ExecutionPolcity unrestricted"
################################################
# Configure the variables below
################################################
$LogDataDir = 'C:\Uploads\'
$ESXiHostCSV = "Z:\Github\Scripts\Zerto\VRADeploymentESXiHosts.csv"
$ZertoServer = 'acsovmzvm01.e911.local'
$ZertoPort = '9669'
$ZertoUser = 'administrator@vsphere.local'
$ZertoPassword = 'Tr!t3cH1'
$SecondsBetweenVRADeployments = "60"
################################################################################
# Nothing to configure below this line - Starting the main function
################################################################################
################################################
# Setting log directory for engine and current month
################################################
$CurrentMonth = get-date -format MM.yy
$CurrentTime = get-date -format hh.mm.ss
$CurrentLogDataDir = $LogDataDir + $CurrentMonth
$CurrentLogDataFile = $LogDataDir + $CurrentMonth + "\BulkVPGCreationLog-" + $CurrentTime + ".txt"
# Testing path exists to engine logging, if not creating it
$ExportDataDirTestPath = test-path $CurrentLogDataDir
if ($ExportDataDirTestPath -eq $False)
{
New-Item -ItemType Directory -Force -Path $CurrentLogDataDir
}
start-transcript -path $CurrentLogDataFile -NoClobber
################################################
# Setting Cert Policy - required for successful auth with the Zerto API 
################################################
add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
################################################
# Building Zerto API string and invoking API
################################################
$baseURL = "https://" + $ZertoServer + ":"+$ZertoPort+"/v1/"
# Authenticating with Zerto APIs
$xZertoSessionURI = $baseURL + "session/add"
$authInfo = ("{0}:{1}" -f $ZertoUser,$ZertoPassword)
$authInfo = [System.Text.Encoding]::UTF8.GetBytes($authInfo)
$authInfo = [System.Convert]::ToBase64String($authInfo)
$headers = @{Authorization=("Basic {0}" -f $authInfo)}
$sessionBody = '{"AuthenticationMethod": "1"}'
$contentType = "application/json"
$xZertoSessionResponse = Invoke-WebRequest -Uri $xZertoSessionURI -Headers $headers -Method POST -Body $sessionBody -ContentType $contentType
#Extracting x-zerto-session from the response, and adding it to the actual API
$xZertoSession = $xZertoSessionResponse.headers.get_item("x-zerto-session")
$zertoSessionHeader = @{"x-zerto-session"=$xZertoSession}
# Get SiteIdentifier for getting Network Identifier later in the script
$SiteInfoURL = $BaseURL+"localsite"
$SiteInfoCMD = Invoke-RestMethod -Uri $SiteInfoURL -TimeoutSec 100 -Headers $zertoSessionHeader -ContentType "application/JSON"
$SiteIdentifier = $SiteInfoCMD | Select SiteIdentifier -ExpandProperty SiteIdentifier
$VRAInstallURL = $BaseURL+"vras"
################################################
# Importing the CSV of ESXi hosts to deploy VRA to
################################################
$ESXiHostCSVImport = Import-Csv $ESXiHostCSV
################################################
# Starting Install Process for each ESXi host specified in the CSV
################################################
foreach ($ESXiHost in $ESXiHostCSVImport)
{
# Setting Current variables for ease of use throughout script
$VRAESXiHostName = $ESXiHost.ESXiHostName
$VRADatastoreName = $ESXiHost.DatastoreName
$VRAPortGroupName = $ESXiHost.PortGroupName
$VRAGroupName = $ESXiHost.VRAGroupName
$VRAMemoryInGB = $ESXiHost.MemoryInGB
$VRADefaultGateway = $ESXiHost.DefaultGateway
$VRASubnetMask = $ESXiHost.SubnetMask
$VRAIPAddress = $ESXiHost.VRAIPAddress
# Get NetworkIdentifier for API
$APINetworkURL = $BaseURL+"virtualizationsites/$SiteIdentifier/networks"
$APINetworkCMD = Invoke-RestMethod -Uri $APINetworkURL -TimeoutSec 100 -Headers $zertoSessionHeader -ContentType $ContentType
$NetworkIdentifier = $APINetworkCMD | Where-Object {$_.VirtualizationNetworkName -eq $VRAPortGroupName}  | Select -ExpandProperty NetworkIdentifier 
# Get HostIdentifier for API
$APIHostURL = $BaseURL+"virtualizationsites/$SiteIdentifier/hosts"
$APIHostCMD = Invoke-RestMethod -Uri $APIHostURL -TimeoutSec 100 -Headers $zertoSessionHeader -ContentType $ContentType
$VRAESXiHostID = $APIHostCMD | Where-Object {$_.VirtualizationHostName -eq $VRAESXiHostName}  | Select -ExpandProperty HostIdentifier 
# Get DatastoreIdentifier for API
$APIDatastoreURL = $BaseURL+"virtualizationsites/$SiteIdentifier/datastores"
$APIDatastoreCMD = Invoke-RestMethod -Uri $APIDatastoreURL -TimeoutSec 100 -Headers $zertoSessionHeader -ContentType $ContentType
$VRADatastoreID = $APIDatastoreCMD | Where-Object {$_.DatastoreName -eq $VRADatastoreName}  | Select -ExpandProperty DatastoreIdentifier 
# Creating JSON Body for API settings
$JSON =
"{
    ""DatastoreIdentifier"":  ""$VRADatastoreID"",
    ""GroupName"":  ""$VRAGroupName"",
    ""HostIdentifier"":  ""$VRAESXiHostID"",
    ""HostRootPassword"":null,
    ""MemoryInGb"":  ""$VRAMemoryInGB"",
    ""NetworkIdentifier"":  ""$NetworkIdentifier"",
    ""UsePublicKeyInsteadOfCredentials"":true,
    ""VraNetworkDataApi"":  {
                              ""DefaultGateway"":  ""$VRADefaultGateway"",
                              ""SubnetMask"":  ""$VRASubnetMask"",
                              ""VraIPAddress"":  ""$VRAIPAddress"",
                              ""VraIPConfigurationTypeApi"":  ""Static""
                          }
}"
write-host "Executing $JSON"
# Now trying API install cmd
Try 
{
 Invoke-RestMethod -Method Post -Uri $VRAInstallURL -Body $JSON -ContentType $ContentType -Headers $zertoSessionHeader
}
Catch {
 Write-Host $_.Exception.ToString()
 $error[0] | Format-List -Force
}
# Waiting xx seconds before deploying the next VRA
write-host "Waiting $SecondsBetweenVRADeployments seconds before deploying the next VRA"
sleep $SecondsBetweenVRADeployments
# End of per Host operations below
}
# End of per Host operations above
################################################
# Stopping logging
################################################
Stop-Transcript