#######################################################################################################################
# This file will be removed when PowerCLI is uninstalled. To make your own scripts run when PowerCLI starts, create a
# file named "Initialize-PowerCLIEnvironment_Custom.ps1" in the same directory as this file, and place your scripts in
# it. The "Initialize-PowerCLIEnvironment_Custom.ps1" is not automatically deleted when PowerCLI is uninstalled.
#######################################################################################################################

# Returns the path (with trailing backslash) to the directory where PowerCLI is installed.
function Get-InstallPath {
   $regKeys = Get-ItemProperty "hklm:\software\VMware, Inc.\VMware vSphere PowerCLI" -ErrorAction SilentlyContinue

   #64bit os fix
   if($regKeys -eq $null){
      $regKeys = Get-ItemProperty "hklm:\software\wow6432node\VMware, Inc.\VMware vSphere PowerCLI"  -ErrorAction SilentlyContinue
   }

   return $regKeys.InstallPath
}

# Load modules
function LoadModules(){
   [xml]$xml = Get-Content ("{0}\vim.psc1" -f (Get-InstallPath))
   $moduleList = Select-Xml  "//PSModule" $xml |%{$_.Node.Name }

   $loaded = Get-Module -Name $moduleList -ErrorAction SilentlyContinue | % {$_.Name}
   $registered = Get-Module -Name $moduleList -ListAvailable -ErrorAction SilentlyContinue  | % {$_.Name}
   $notLoaded = $registered | ? {$loaded -notcontains $_}

   foreach ($module in $registered) {
      if ($loaded -notcontains $module) {
         Import-Module $module
      }
   }
}
LoadModules

$productName = "vSphere PowerCLI"
$productShortName = "PowerCLI"
$version = Get-PowerCLIVersion
$windowTitle = "VMware $productName {0}.{1}" -f $version.Major, $version.Minor
$host.ui.RawUI.WindowTitle = "$windowTitle"
$CustomInitScriptName = "Initialize-PowerCLIEnvironment_Custom.ps1"
$currentDir = Split-Path $MyInvocation.MyCommand.Path
$CustomInitScript = Join-Path $currentDir $CustomInitScriptName

#returns the version of Powershell
# Note: When using, make sure to surround Get-PSVersion with parentheses to force value comparison
function Get-PSVersion {
    if (test-path variable:psversiontable) {
		$psversiontable.psversion
	} else {
		[version]"1.0.0.0"
	}
}

# Loads additional snapins and their init scripts
function LoadSnapins(){
   [xml]$xml = Get-Content ("{0}\vim.psc1" -f (Get-InstallPath))
   $snapinList = Select-Xml  "//PSSnapIn" $xml |%{$_.Node.Name }

   $loaded = Get-PSSnapin -Name $snapinList -ErrorAction SilentlyContinue | % {$_.Name}
   $registered = Get-PSSnapin -Name $snapinList -Registered -ErrorAction SilentlyContinue  | % {$_.Name}
   $notLoaded = $registered | ? {$loaded -notcontains $_}

   foreach ($snapin in $registered) {
      if ($loaded -notcontains $snapin) {
         Add-PSSnapin $snapin
      }

      # Load the Intitialize-<snapin_name_with_underscores>.ps1 file
      # File lookup is based on install path instead of script folder because the PowerCLI
      # shortuts load this script through dot-sourcing and script path is not available.
      $filePath = "{0}Scripts\Initialize-{1}.ps1" -f (Get-InstallPath), $snapin.ToString().Replace(".", "_")
      if (Test-Path $filePath) {
         & $filePath
      }
   }
}
LoadSnapins

# Update PowerCLI version after snap-in load
$version = Get-PowerCLIVersion
$windowTitle = "VMware $productName {0}.{1} Release 1" -f $version.Major, $version.Minor
$host.ui.RawUI.WindowTitle = "$windowTitle"

function global:Get-VICommand([string] $Name = "*") {
  get-command -pssnapin VMware.* -Name $Name
}

function global:Get-LicensingCommand([string] $Name = "*") {
  get-command -pssnapin VMware.VimAutomation.License -Name $Name
}

function global:Get-ImageBuilderCommand([string] $Name = "*") {
  get-command -pssnapin VMware.ImageBuilder -Name $Name
}

function global:Get-AutoDeployCommand([string] $Name = "*") {
  get-command -pssnapin VMware.DeployAutomation -Name $Name
}

# Launch text
#write-host "          Welcome to VMware $productName!"
#write-host ""
#write-host "Log in to a vCenter Server or ESX host:              " -NoNewLine
#write-host "Connect-VIServer" -foregroundcolor yellow
#write-host "To find out what commands are available, type:       " -NoNewLine
#write-host "Get-VICommand" -foregroundcolor yellow
#write-host "To show searchable help for all PowerCLI commands:   " -NoNewLine
#write-host "Get-PowerCLIHelp" -foregroundcolor yellow
#write-host "Once you've connected, display all virtual machines: " -NoNewLine
#write-host "Get-VM" -foregroundcolor yellow
#write-host "If you need more help, visit the PowerCLI community: " -NoNewLine
#write-host "Get-PowerCLICommunity" -foregroundcolor yellow
#write-host ""
#write-host "       Copyright (C) VMware, Inc. All rights reserved."
#write-host ""
#write-host ""

# Error message to update to version 2.0 of PowerShell
# Note: Make sure to surround Get-PSVersion with parentheses to force value comparison
if((Get-PSVersion) -lt "2.0"){
    $psVersion = Get-PSVersion
    Write-Error "$productShortName requires Powershell 2.0! The version of Powershell installed on this computer is $psVersion." -Category NotInstalled
}

# Modify the prompt function to change the console prompt.
# Save the previous function, to allow restoring it back.
$originalPromptFunction = $function:prompt
function global:prompt{

    # change prompt text
    Write-Host "$productShortName " -NoNewLine -foregroundcolor Green
    Write-Host ((Get-location).Path + ">") -NoNewLine
    return " "
}

# Tab Expansion for parameters of enum types.
# This functionality requires powershell 2.0
# Note: Make sure to surround Get-PSVersion with parentheses to force value comparison
if((Get-PSVersion) -eq "2.0"){

    #modify the tab expansion function to support enum parameter expansion
    $global:originalTabExpansionFunction = $function:TabExpansion

    function global:TabExpansion {
       param($line, $lastWord)

       $originalResult = & $global:originalTabExpansionFunction $line $lastWord

       if ($originalResult) {
          return $originalResult
       }
       #ignore parsing errors. if there are errors in the syntax, try anyway
       $tokens = [System.Management.Automation.PSParser]::Tokenize($line, [ref] $null)

       if ($tokens)
       {
           $lastToken = $tokens[$tokens.count - 1]

           $startsWith = ""

           # locate the last parameter token, which value is to be expanded
           switch($lastToken.Type){
               'CommandParameter' {
                    #... -Parameter<space>

                    $paramToken = $lastToken
               }
               'CommandArgument' {
                    #if the last token is argument, that can be a partially spelled value
                    if($lastWord){
                        #... -Parameter Argument  <<< partially spelled argument, $lastWord == Argument
                        #... -Parameter Argument Argument

                        $startsWith = $lastWord

                        $prevToken = $tokens[$tokens.count - 2]
                        #if the argument is not preceeded by a paramter, then it is a value for a positional parameter.
                        if ($prevToken.Type -eq 'CommandParameter') {
                            $paramToken = $prevToken
                        }
                    }
                    #else handles "... -Parameter Argument<space>" and "... -Parameter Argument Argument<space>" >>> which means the argument is entirely spelled
               }
           }

           # if a parameter is found for the argument that is tab-expanded
           if ($paramToken) {
               #locates the 'command' token, that this parameter belongs to
               [int]$groupLevel = 0
               for($i=$tokens.Count-1; $i -ge 0; $i--) {
                   $currentToken = $tokens[$i]
                   if ( ($currentToken.Type -eq 'Command') -and ($groupLevel -eq 0) ) {
                      $cmdletToken = $currentToken
                      break;
                   }

                   if ($currentToken.Type -eq 'GroupEnd') {
                      $groupLevel += 1
                   }
                   if ($currentToken.Type -eq 'GroupStart') {
                      $groupLevel -= 1
                   }
               }

               if ($cmdletToken) {
                   # getting command object
                   $cmdlet = Get-Command $cmdletToken.Content
                   # gettint parameter information
                   $parameter = $cmdlet.Parameters[$paramToken.Content.Replace('-','')]

                   # getting the data type of the parameter
                   $parameterType = $parameter.ParameterType

                   if ($parameterType.IsEnum) {
                      # if the type is Enum then the values are the enum values
                      $values = [System.Enum]::GetValues($parameterType)
                   } elseif($parameterType.IsArray) {
                      $elementType = $parameterType.GetElementType()

                      if($elementType.IsEnum) {
                        # if the type is an array of Enum then values are the enum values
                        $values = [System.Enum]::GetValues($elementType)
                      }
                   }

                   if($values) {
                      if ($startsWith) {
                          return ($values | where { $_ -like "${startsWith}*" })
                      } else {
                          return $values
                      }
                   }
               }
           }
       }
    }
}

# Opens documentation file
function global:Get-PowerCLIHelp{
   $ChmFilePath = Join-Path (Get-InstallPath) "VICore Documentation\$productName Cmdlets Reference.chm"
   $docProcess = [System.Diagnostics.Process]::Start($ChmFilePath)
}

# Opens toolkit community url with default browser
function global:Get-PowerCLICommunity{
    $link = "http://communities.vmware.com/community/vmtn/vsphere/automationtools/windows_toolkit"
    $browserProcess = [System.Diagnostics.Process]::Start($link)
}

# Find and execute custom initialization file
$existsCustomInitScript = Test-Path $CustomInitScript
if($existsCustomInitScript) {
   & $CustomInitScript
}

# SIG # Begin signature block
# MIIezQYJKoZIhvcNAQcCoIIevjCCHroCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU5mZJFh6g0OHyI2sOGzxU620K
# hWqgghmqMIID7jCCA1egAwIBAgIQfpPr+3zGTlnqS5p31Ab8OzANBgkqhkiG9w0B
# AQUFADCBizELMAkGA1UEBhMCWkExFTATBgNVBAgTDFdlc3Rlcm4gQ2FwZTEUMBIG
# A1UEBxMLRHVyYmFudmlsbGUxDzANBgNVBAoTBlRoYXd0ZTEdMBsGA1UECxMUVGhh
# d3RlIENlcnRpZmljYXRpb24xHzAdBgNVBAMTFlRoYXd0ZSBUaW1lc3RhbXBpbmcg
# Q0EwHhcNMTIxMjIxMDAwMDAwWhcNMjAxMjMwMjM1OTU5WjBeMQswCQYDVQQGEwJV
# UzEdMBsGA1UEChMUU3ltYW50ZWMgQ29ycG9yYXRpb24xMDAuBgNVBAMTJ1N5bWFu
# dGVjIFRpbWUgU3RhbXBpbmcgU2VydmljZXMgQ0EgLSBHMjCCASIwDQYJKoZIhvcN
# AQEBBQADggEPADCCAQoCggEBALGss0lUS5ccEgrYJXmRIlcqb9y4JsRDc2vCvy5Q
# WvsUwnaOQwElQ7Sh4kX06Ld7w3TMIte0lAAC903tv7S3RCRrzV9FO9FEzkMScxeC
# i2m0K8uZHqxyGyZNcR+xMd37UWECU6aq9UksBXhFpS+JzueZ5/6M4lc/PcaS3Er4
# ezPkeQr78HWIQZz/xQNRmarXbJ+TaYdlKYOFwmAUxMjJOxTawIHwHw103pIiq8r3
# +3R8J+b3Sht/p8OeLa6K6qbmqicWfWH3mHERvOJQoUvlXfrlDqcsn6plINPYlujI
# fKVOSET/GeJEB5IL12iEgF1qeGRFzWBGflTBE3zFefHJwXECAwEAAaOB+jCB9zAd
# BgNVHQ4EFgQUX5r1blzMzHSa1N197z/b7EyALt0wMgYIKwYBBQUHAQEEJjAkMCIG
# CCsGAQUFBzABhhZodHRwOi8vb2NzcC50aGF3dGUuY29tMBIGA1UdEwEB/wQIMAYB
# Af8CAQAwPwYDVR0fBDgwNjA0oDKgMIYuaHR0cDovL2NybC50aGF3dGUuY29tL1Ro
# YXd0ZVRpbWVzdGFtcGluZ0NBLmNybDATBgNVHSUEDDAKBggrBgEFBQcDCDAOBgNV
# HQ8BAf8EBAMCAQYwKAYDVR0RBCEwH6QdMBsxGTAXBgNVBAMTEFRpbWVTdGFtcC0y
# MDQ4LTEwDQYJKoZIhvcNAQEFBQADgYEAAwmbj3nvf1kwqu9otfrjCR27T4IGXTdf
# plKfFo3qHJIJRG71betYfDDo+WmNI3MLEm9Hqa45EfgqsZuwGsOO61mWAK3ODE2y
# 0DGmCFwqevzieh1XTKhlGOl5QGIllm7HxzdqgyEIjkHq3dlXPx13SYcqFgZepjhq
# IhKjURmDfrYwggSjMIIDi6ADAgECAhAOz/Q4yP6/NW4E2GqYGxpQMA0GCSqGSIb3
# DQEBBQUAMF4xCzAJBgNVBAYTAlVTMR0wGwYDVQQKExRTeW1hbnRlYyBDb3Jwb3Jh
# dGlvbjEwMC4GA1UEAxMnU3ltYW50ZWMgVGltZSBTdGFtcGluZyBTZXJ2aWNlcyBD
# QSAtIEcyMB4XDTEyMTAxODAwMDAwMFoXDTIwMTIyOTIzNTk1OVowYjELMAkGA1UE
# BhMCVVMxHTAbBgNVBAoTFFN5bWFudGVjIENvcnBvcmF0aW9uMTQwMgYDVQQDEytT
# eW1hbnRlYyBUaW1lIFN0YW1waW5nIFNlcnZpY2VzIFNpZ25lciAtIEc0MIIBIjAN
# BgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAomMLOUS4uyOnREm7Dv+h8GEKU5Ow
# mNutLA9KxW7/hjxTVQ8VzgQ/K/2plpbZvmF5C1vJTIZ25eBDSyKV7sIrQ8Gf2Gi0
# jkBP7oU4uRHFI/JkWPAVMm9OV6GuiKQC1yoezUvh3WPVF4kyW7BemVqonShQDhfu
# ltthO0VRHc8SVguSR/yrrvZmPUescHLnkudfzRC5xINklBm9JYDh6NIipdC6Anqh
# d5NbZcPuF3S8QYYq3AhMjJKMkS2ed0QfaNaodHfbDlsyi1aLM73ZY8hJnTrFxeoz
# C9Lxoxv0i77Zs1eLO94Ep3oisiSuLsdwxb5OgyYI+wu9qU+ZCOEQKHKqzQIDAQAB
# o4IBVzCCAVMwDAYDVR0TAQH/BAIwADAWBgNVHSUBAf8EDDAKBggrBgEFBQcDCDAO
# BgNVHQ8BAf8EBAMCB4AwcwYIKwYBBQUHAQEEZzBlMCoGCCsGAQUFBzABhh5odHRw
# Oi8vdHMtb2NzcC53cy5zeW1hbnRlYy5jb20wNwYIKwYBBQUHMAKGK2h0dHA6Ly90
# cy1haWEud3Muc3ltYW50ZWMuY29tL3Rzcy1jYS1nMi5jZXIwPAYDVR0fBDUwMzAx
# oC+gLYYraHR0cDovL3RzLWNybC53cy5zeW1hbnRlYy5jb20vdHNzLWNhLWcyLmNy
# bDAoBgNVHREEITAfpB0wGzEZMBcGA1UEAxMQVGltZVN0YW1wLTIwNDgtMjAdBgNV
# HQ4EFgQURsZpow5KFB7VTNpSYxc/Xja8DeYwHwYDVR0jBBgwFoAUX5r1blzMzHSa
# 1N197z/b7EyALt0wDQYJKoZIhvcNAQEFBQADggEBAHg7tJEqAEzwj2IwN3ijhCcH
# bxiy3iXcoNSUA6qGTiWfmkADHN3O43nLIWgG2rYytG2/9CwmYzPkSWRtDebDZw73
# BaQ1bHyJFsbpst+y6d0gxnEPzZV03LZc3r03H0N45ni1zSgEIKOq8UvEiCmRDoDR
# EfzdXHZuT14ORUZBbg2w6jiasTraCXEQ/Bx5tIB7rGn0/Zy2DBYr8X9bCT2bW+IW
# yhOBbQAuOA2oKY8s4bL0WqkBrxWcLC9JG9siu8P+eJRRw4axgohd8D20UaF5Mysu
# e7ncIAkTcetqGVvP6KUwVyyJST+5z3/Jvz4iaGNTmr1pdKzFHTx/kuDDvBzYBHUw
# ggVhMIIESaADAgECAhBEUa03F8+iI3H/vAffE+ZdMA0GCSqGSIb3DQEBBQUAMIG0
# MQswCQYDVQQGEwJVUzEXMBUGA1UEChMOVmVyaVNpZ24sIEluYy4xHzAdBgNVBAsT
# FlZlcmlTaWduIFRydXN0IE5ldHdvcmsxOzA5BgNVBAsTMlRlcm1zIG9mIHVzZSBh
# dCBodHRwczovL3d3dy52ZXJpc2lnbi5jb20vcnBhIChjKTEwMS4wLAYDVQQDEyVW
# ZXJpU2lnbiBDbGFzcyAzIENvZGUgU2lnbmluZyAyMDEwIENBMB4XDTEzMTAxNzAw
# MDAwMFoXDTE2MTExNTIzNTk1OVowgaQxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpD
# YWxpZm9ybmlhMRIwEAYDVQQHEwlQYWxvIEFsdG8xFTATBgNVBAoUDFZNd2FyZSwg
# SW5jLjE+MDwGA1UECxM1RGlnaXRhbCBJRCBDbGFzcyAzIC0gTWljcm9zb2Z0IFNv
# ZnR3YXJlIFZhbGlkYXRpb24gdjIxFTATBgNVBAMUDFZNd2FyZSwgSW5jLjCCASIw
# DQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBANAjA/U0xYDd2HspeIu1s4+EO2I0
# /eaO9IwjOjdDDhdjoohR8w0ARFQPv6Y/WtVTev2HOZbS5FPwVr0t2lOHUP2Aneuo
# SfrFX1KIgAJqC9hClZMzGTyy1J5TGxH5MgZg65irtjVC3LcQvVZL6XRsRXnIYIQI
# xas7cb+Lfx5ByGvcs9qY6XJsLvhDnzUbk7Gfxdm5WUjcfmmVGS1h7Jtlj2MYGDL8
# QgTjIqMLDkIqa4guBYubsTUKz8TgDrMG207O9UqldDRlwZ/fTTVTddhb7/aJhvM7
# NfOZdtAbKsqrySNdCm8U/2EVopiNlPEvZVrLK3g99NmyOqv/Cok2pJ5MaYkCAwEA
# AaOCAXswggF3MAkGA1UdEwQCMAAwDgYDVR0PAQH/BAQDAgeAMEAGA1UdHwQ5MDcw
# NaAzoDGGL2h0dHA6Ly9jc2MzLTIwMTAtY3JsLnZlcmlzaWduLmNvbS9DU0MzLTIw
# MTAuY3JsMEQGA1UdIAQ9MDswOQYLYIZIAYb4RQEHFwMwKjAoBggrBgEFBQcCARYc
# aHR0cHM6Ly93d3cudmVyaXNpZ24uY29tL3JwYTATBgNVHSUEDDAKBggrBgEFBQcD
# AzBxBggrBgEFBQcBAQRlMGMwJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLnZlcmlz
# aWduLmNvbTA7BggrBgEFBQcwAoYvaHR0cDovL2NzYzMtMjAxMC1haWEudmVyaXNp
# Z24uY29tL0NTQzMtMjAxMC5jZXIwHwYDVR0jBBgwFoAUz5mp6nsm9EvJjo/X8AUm
# 7+PSp50wEQYJYIZIAYb4QgEBBAQDAgQQMBYGCisGAQQBgjcCARsECDAGAQEAAQH/
# MA0GCSqGSIb3DQEBBQUAA4IBAQAjoBynotANZpJFCdmSBh8B6Xah7eaHjwaUIDp0
# CP2mHQLIbWR5+hCqkQQs+OlZOucK6cRqi9yaGNSuYZEIiQqxwkq3ur5H1OurDUWX
# aqQJfDdYvR6S8LjoYwWdzah12VriO2vVja0dUuFBAJdlUEJQY/2UyTo0pmedEQmX
# Y8pSVsmux3MMW7fjU/+hUgRP6Yg+lUN81jvniFU2P5i7YBciyOf7ekP7x8zg+ei6
# P5OfSDqxIz5h8guu7v+Imvg67iBeQN1UYCeLBBxTi8u1zhtmXfjEEmfWFlUJK2EI
# vAxtco3KLObeqmKwSiWM28zQs13D5UqYgGxN42+VJTfy2vMrMIIFmjCCA4KgAwIB
# AgIKYRmT5AAAAAAAHDANBgkqhkiG9w0BAQUFADB/MQswCQYDVQQGEwJVUzETMBEG
# A1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWlj
# cm9zb2Z0IENvcnBvcmF0aW9uMSkwJwYDVQQDEyBNaWNyb3NvZnQgQ29kZSBWZXJp
# ZmljYXRpb24gUm9vdDAeFw0xMTAyMjIxOTI1MTdaFw0yMTAyMjIxOTM1MTdaMIHK
# MQswCQYDVQQGEwJVUzEXMBUGA1UEChMOVmVyaVNpZ24sIEluYy4xHzAdBgNVBAsT
# FlZlcmlTaWduIFRydXN0IE5ldHdvcmsxOjA4BgNVBAsTMShjKSAyMDA2IFZlcmlT
# aWduLCBJbmMuIC0gRm9yIGF1dGhvcml6ZWQgdXNlIG9ubHkxRTBDBgNVBAMTPFZl
# cmlTaWduIENsYXNzIDMgUHVibGljIFByaW1hcnkgQ2VydGlmaWNhdGlvbiBBdXRo
# b3JpdHkgLSBHNTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAK8kCAgp
# ejWeYAyq50s7Ttx8vDxFHLsr4P4pAvlXCKNkhRUn9fGtyDGJXSLoKqqmQrOP+LlV
# t7G3S7P+j34HV+zvQ9tmYhVhz2ANpNje+ODDYgg9VBPrScpZVIUm5SuPG5/r9aGR
# wjNJ2ENjalJL0o/ocFFN0Ylpe8dw9rPcEnTbe11LVtOWvxV3obD0oiXyrxySZxjl
# 9AYE75C55ADk3Tq1Gf8CuvQ87uCL6zeL7PTXrPL28D2v3XWRMxkdHEDLdCQZIZPZ
# FP6sKlLHj9UESeSNY0eIPGmDy/5HvSt+T8WVrg6d1NFDwGdz4xQIfuU/n3O4MwrP
# XT80h5aK7lPoJRUCAwEAAaOByzCByDARBgNVHSAECjAIMAYGBFUdIAAwDwYDVR0T
# AQH/BAUwAwEB/zALBgNVHQ8EBAMCAYYwHQYDVR0OBBYEFH/TZafC3ey78DAJ80M5
# +gKvMzEzMB8GA1UdIwQYMBaAFGL7CiFbf0NuEdoJVFBr9dKWcfGeMFUGA1UdHwRO
# MEwwSqBIoEaGRGh0dHA6Ly9jcmwubWljcm9zb2Z0LmNvbS9wa2kvY3JsL3Byb2R1
# Y3RzL01pY3Jvc29mdENvZGVWZXJpZlJvb3QuY3JsMA0GCSqGSIb3DQEBBQUAA4IC
# AQCBKoIWjDRnK+UD6zR7jKKjUIr0VYbxHoyOrn3uAxnOcpUYSK1iEf0g/T9HBgFa
# 4uBvjBUsTjxqUGwLNqPPeg2cQrxc+BnVYONp5uIjQWeMaIN2K4+Toyq1f75Z+6nJ
# siaPyqLzghuYPpGVJ5eGYe5bXQdrzYao4mWAqOIV4rK+IwVqugzzR5NNrKSMB3k5
# wGESOgUNiaPsn1eJhPvsynxHZhSR2LYPGV3muEqsvEfIcUOW5jIgpdx3hv0844tx
# 23ubA/y3HTJk6xZSoEOj+i6tWZJOfMfyM0JIOFE6fDjHGyQiKEAeGkYfF9sY9/An
# NWy4Y9nNuWRdK6Ve78YptPLH+CHMBLpX/QG2q8Zn+efTmX/09SL6cvX9/zocQjqh
# +YAYpe6NHNRmnkUB/qru//sXjzD38c0pxZ3stdVJAD2FuMu7kzonaknAMK5myfcj
# KDJ2+aSDVshIzlqWqqDMDMR/tI6Xr23jVCfDn4bA1uRzCJcF29BUYl4DSMLVn3+n
# ZozQnbBP1NOYX0t6yX+yKVLQEoDHD1S2HmfNxqBsEQOE00h15yr+sDtuCjqma3aZ
# BaPxd2hhMxRHBvxTf1K9khRcSiRqZ4yvjZCq0PZ5IRuTJnzDzh69iDiSrkXGGWpJ
# ULMF+K5ZN4pqJQOUsVmBUOi6g4C3IzX0drlnHVkYrSCNlDCCBgowggTyoAMCAQIC
# EFIA5aolVvwahu2WydRLM8cwDQYJKoZIhvcNAQEFBQAwgcoxCzAJBgNVBAYTAlVT
# MRcwFQYDVQQKEw5WZXJpU2lnbiwgSW5jLjEfMB0GA1UECxMWVmVyaVNpZ24gVHJ1
# c3QgTmV0d29yazE6MDgGA1UECxMxKGMpIDIwMDYgVmVyaVNpZ24sIEluYy4gLSBG
# b3IgYXV0aG9yaXplZCB1c2Ugb25seTFFMEMGA1UEAxM8VmVyaVNpZ24gQ2xhc3Mg
# MyBQdWJsaWMgUHJpbWFyeSBDZXJ0aWZpY2F0aW9uIEF1dGhvcml0eSAtIEc1MB4X
# DTEwMDIwODAwMDAwMFoXDTIwMDIwNzIzNTk1OVowgbQxCzAJBgNVBAYTAlVTMRcw
# FQYDVQQKEw5WZXJpU2lnbiwgSW5jLjEfMB0GA1UECxMWVmVyaVNpZ24gVHJ1c3Qg
# TmV0d29yazE7MDkGA1UECxMyVGVybXMgb2YgdXNlIGF0IGh0dHBzOi8vd3d3LnZl
# cmlzaWduLmNvbS9ycGEgKGMpMTAxLjAsBgNVBAMTJVZlcmlTaWduIENsYXNzIDMg
# Q29kZSBTaWduaW5nIDIwMTAgQ0EwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEK
# AoIBAQD1I0tepdeKuzLp1Ff37+THJn6tGZj+qJ19lPY2axDXdYEwfwRof8srdR7N
# HQiM32mUpzejnHuA4Jnh7jdNX847FO6G1ND1JzW8JQs4p4xjnRejCKWrsPvNamKC
# TNUh2hvZ8eOEO4oqT4VbkAFPyad2EH8nA3y+rn59wd35BbwbSJxp58CkPDxBAD7f
# luXF5JRx1lUBxwAmSkA8taEmqQynbYCOkCV7z78/HOsvlvrlh3fGtVayejtUMFMb
# 32I0/x7R9FqTKIXlTBdOflv9pJOZf9/N76R17+8V9kfn+Bly2C40Gqa0p0x+vbtP
# DD1X8TDWpjaO1oB21xkupc1+NC2JAgMBAAGjggH+MIIB+jASBgNVHRMBAf8ECDAG
# AQH/AgEAMHAGA1UdIARpMGcwZQYLYIZIAYb4RQEHFwMwVjAoBggrBgEFBQcCARYc
# aHR0cHM6Ly93d3cudmVyaXNpZ24uY29tL2NwczAqBggrBgEFBQcCAjAeGhxodHRw
# czovL3d3dy52ZXJpc2lnbi5jb20vcnBhMA4GA1UdDwEB/wQEAwIBBjBtBggrBgEF
# BQcBDARhMF+hXaBbMFkwVzBVFglpbWFnZS9naWYwITAfMAcGBSsOAwIaBBSP5dMa
# hqyNjmvDz4Bq1EgYLHsZLjAlFiNodHRwOi8vbG9nby52ZXJpc2lnbi5jb20vdnNs
# b2dvLmdpZjA0BgNVHR8ELTArMCmgJ6AlhiNodHRwOi8vY3JsLnZlcmlzaWduLmNv
# bS9wY2EzLWc1LmNybDA0BggrBgEFBQcBAQQoMCYwJAYIKwYBBQUHMAGGGGh0dHA6
# Ly9vY3NwLnZlcmlzaWduLmNvbTAdBgNVHSUEFjAUBggrBgEFBQcDAgYIKwYBBQUH
# AwMwKAYDVR0RBCEwH6QdMBsxGTAXBgNVBAMTEFZlcmlTaWduTVBLSS0yLTgwHQYD
# VR0OBBYEFM+Zqep7JvRLyY6P1/AFJu/j0qedMB8GA1UdIwQYMBaAFH/TZafC3ey7
# 8DAJ80M5+gKvMzEzMA0GCSqGSIb3DQEBBQUAA4IBAQBWIuY0pMRhy0i5Aa1WqGQP
# 2YyRxLvMDOWteqAif99HOEotbNF/cRp87HCpsfBP5A8MU/oVXv50mEkkhYEmHJEU
# R7BMY4y7oTTUxkXoDYUmcwPQqYxkbdxxkuZFBWAVWVE5/FgUa/7UpO15awgMQXLn
# NyIGCb4j6T9Emh7pYZ3MsZBc/D3SjaxCPWU21LQ9QCiPmxDPIybMSyDLkB9djEw0
# yjzY5TfWb6UgvTTrJtmuDefFmvehtCGRM2+G6Fi7JXx0Dlj+dRtjP84xfJuPG5ae
# xVN2hFucrZH6rO2Tul3IIVPCglNjrxINUIcRGz1UUpaKLJw9khoImgUux5OlSJHT
# MYIEjTCCBIkCAQEwgckwgbQxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5WZXJpU2ln
# biwgSW5jLjEfMB0GA1UECxMWVmVyaVNpZ24gVHJ1c3QgTmV0d29yazE7MDkGA1UE
# CxMyVGVybXMgb2YgdXNlIGF0IGh0dHBzOi8vd3d3LnZlcmlzaWduLmNvbS9ycGEg
# KGMpMTAxLjAsBgNVBAMTJVZlcmlTaWduIENsYXNzIDMgQ29kZSBTaWduaW5nIDIw
# MTAgQ0ECEERRrTcXz6Ijcf+8B98T5l0wCQYFKw4DAhoFAKCBijAZBgkqhkiG9w0B
# CQMxDAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAj
# BgkqhkiG9w0BCQQxFgQUvWwP9jvOvwlRZkMLchwY/hxPMlYwKgYKKwYBBAGCNwIB
# DDEcMBqhGIAWaHR0cDovL3d3dy52bXdhcmUuY29tLzANBgkqhkiG9w0BAQEFAASC
# AQBZl1LQxBxqkRwvmNLBnTW82B8NuS2iHdnUY7rx7WwNVb6sFa+xJBWKzoDJgnKu
# D8tCongs+icEEMkopaDWzbiTYXG+K6dHBzzxpf85ZMr3iuq5hRfeQVSlGfm09uAi
# 3R1VhVQSb9LLY4GyT3xORp+TuUrh+0jAPbQ0hTDBPupn6iF254PotKtdNus6n252
# C00qsAi7Dkg50yogHNkSVPWicpFMWa8NHGwuyPxdCGkHQj4nRRzUeHRTMP3r2Bam
# xT3bAxlgbfibIOymS7Y6CljCpWf/ewHTOM/v+JkbqOrJUNQa+tspq+pcFpyexdpW
# AA0SZK7yrZyHjNHEbQnuiZxRoYICCzCCAgcGCSqGSIb3DQEJBjGCAfgwggH0AgEB
# MHIwXjELMAkGA1UEBhMCVVMxHTAbBgNVBAoTFFN5bWFudGVjIENvcnBvcmF0aW9u
# MTAwLgYDVQQDEydTeW1hbnRlYyBUaW1lIFN0YW1waW5nIFNlcnZpY2VzIENBIC0g
# RzICEA7P9DjI/r81bgTYapgbGlAwCQYFKw4DAhoFAKBdMBgGCSqGSIb3DQEJAzEL
# BgkqhkiG9w0BBwEwHAYJKoZIhvcNAQkFMQ8XDTE1MDIyNzEyNTMwM1owIwYJKoZI
# hvcNAQkEMRYEFFD7HrS5uGvM5xb3lM9joSKz7vTEMA0GCSqGSIb3DQEBAQUABIIB
# AJjo3sLg+D/X0wCEqJdv7n8OwBYcf1CIaLOdNlbYOKu1PM0MQeGb3lHijmgrZpEO
# tyba0p84KZ1+Kh4keS0wEiAxwdCj5g1KH9Kcz6CzrUIlONX6Lu+sMNDDb69QXKcH
# 014HlTCQjt90kuG7dTY6CSFe2G+LMR7LP308Xv/m2xypKJJg7HOjLhPardpVuSJ3
# kGMlSC2TEdKRB8ioZ+NJGvnlkZahu/urRUEGjMhBgy63IzfzdQbe/3VCXzEeWSLo
# G5W6C51ir3VmO6xxfUJs8j4RDfdQsDc0CX68iIjxLMQSC5xzCF+s3wyzXkCQDt4g
# EifWorllHwNzjLzRW32uN0M=
# SIG # End signature block
