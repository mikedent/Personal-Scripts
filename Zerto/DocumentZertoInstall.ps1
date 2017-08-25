$ZertoServer = '192.168.13.30'
$ZertoPort = '9669'
$ZertoUser = 'administrator@vsphere.local'
$ZertoPassword = 'Tr!t3cH1'
$vCenterServer = '192.168.13.56'
$vCenterUser = 'administrator@vsphere.local'
$vCenterPassword = 'Tr!t3cH1!'
################################################
# Setting Cert Policy - required for successful auth with the Zerto API 
################################################
Add-Type -TypeDefinition @"
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
[System.Net.ServicePointManager]::CertificatePolicy = New-Object -TypeName TrustAllCertsPolicy
# Building Zerto API string and invoking API
$baseURL = 'https://' + $ZertoServer + ':'+$ZertoPort+'/v1/'
# Authenticating with Zerto APIs
$xZertoSessionURI = $baseURL + 'session/add'
$authInfo = ('{0}:{1}' -f $ZertoUser, $ZertoPassword)
$authInfo = [System.Text.Encoding]::UTF8.GetBytes($authInfo)
$authInfo = [System.Convert]::ToBase64String($authInfo)
$headers = @{
  Authorization = ('Basic {0}' -f $authInfo)
}
$sessionBody = '{"AuthenticationMethod": "1"}'
$contentType = 'application/json'
$xZertoSessionResponse = Invoke-WebRequest -Uri $xZertoSessionURI -Headers $headers -Method POST -Body $sessionBody -ContentType $contentType
# Extracting x-zerto-session from the response, and adding it to the actual API
$xZertoSession = $xZertoSessionResponse.headers.get_item('x-zerto-session')
$zertSessionHeader = @{
  'x-zerto-session' = $xZertoSession
}

 #Get Virtual Protection Group List
$VPGsURL = $BaseURL+"vpgs"
$VPGsCMD = Invoke-RestMethod -Uri $VPGsURL -TimeoutSec 100 -Headers $zertSessionHeader -ContentType "application/JSON"
$VPGs = $VPGsCMD | Select *
$VPGs = $VPGsCMD | Select VPGName, Priority, Status, VMsCount, UsedStorageInMb, ThroughputinMb, ConfiguredRPOSeconds, ActualRpo | Export-CSV -Path "C:\Uploads\vpg.csv"

# Get VRA List
$VRAsURL = $BaseURL+"vras"
$VRAsCMD = Invoke-RestMethod -Uri $VRAsURL -TimeoutSec 100 -Headers $zertSessionHeader -ContentType "application/JSON"
$VRAs = $VRAsCMD | Select VraName, vraversion, datastorename, ipaddress, memoryingb, networkname, vragroup  | Export-Csv -Path "C:\Uploads\vra.csv"
$VRAs

# Get Protected VMs List
$ProtectedVMsURL = $baseURL+'vms'
$ProtectedVMsCMD = Invoke-RestMethod -Uri $ProtectedVMsURL -TimeoutSec 100 -Headers $zertSessionHeader -ContentType 'application/JSON'
#$ProtectedVMs = $ProtectedVMsCMD | Select *
$ProtectedVMs = $ProtectedVMsCMD |
Select-Object -Property VpgName, VmName, LastTest, JournalUsedStorageMb, ProvisionedStorageInMB, SourceSite, TargetSite, Priority  |
Export-Csv -Path 'C:\Uploads\protectecvm.csv'