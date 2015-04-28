#########################################################################################
#   MICROSOFT LEGAL STATEMENT FOR SAMPLE SCRIPTS/CODE
#########################################################################################
#   This Sample Code is provided for the purpose of illustration only and is not 
#   intended to be used in a production environment.
#
#   THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY 
#   OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED 
#   WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.
#
#   We grant You a nonexclusive, royalty-free right to use and modify the Sample Code 
#   and to reproduce and distribute the object code form of the Sample Code, provided 
#   that You agree: 
#   (i)    to not use Our name, logo, or trademarks to market Your software product 
#          in which the Sample Code is embedded; 
#   (ii)   to include a valid copyright notice on Your software product in which 
#          the Sample Code is embedded; and 
#   (iii)  to indemnify, hold harmless, and defend Us and Our suppliers from and 
#          against any claims or lawsuits, including attorneys’ fees, that arise 
#          or result from the use or distribution of the Sample Code.
#########################################################################################

#******************************************************************************
# File:     Get-TimeZone.ps1
# Date:     06/03/2009
# Version:  1.0.0
#
# Purpose:  PowerShell script get time zone information.
#
# Usage:    Get-TimeZone.ps1 <-help | -list>
#
# Requires: TimeZoneLib.ps1, TimeZoneCSharp.ps1, CompileCSharpLib.ps1
#           in the same folder.
#
# Copyright (C) 2009 Microsoft Corporation
#
#
# Revisions:
# ----------
# 1.0.0   06/03/2009   Created script.
#
#******************************************************************************


#*******************************************************************
# Declare Parameters
#*******************************************************************
param(
    [switch] $list = $false,
    [switch] $help = $false
)


#*******************************************************************
# Declare Global Variables and Constants
#*******************************************************************

# Initialize variables
$invocation = (Get-Variable MyInvocation -Scope 0).Value
$scriptPath = Split-Path $Invocation.MyCommand.Path


#*******************************************************************
#  Load Function Libraries
#*******************************************************************
$timeZoneCSharpPath = Join-Path $ScriptPath TimeZoneCSharp.ps1
. $timeZoneCSharpPath

$compileCSharpLibPath = Join-Path $ScriptPath CompileCSharpLib.ps1
. $compileCSharpLibPath

## Compile our C# code
Compile-CSharp $timeZoneCSharpCode

$timeZoneLibPath = Join-Path $ScriptPath TimeZoneLib.ps1
. $timeZoneLibPath


#*******************************************************************
# Function Show-Usage()
#
# Purpose:   Shows the correct usage to the user.
#
# Input:     None
#
# Output:    Help messages are displayed on screen.
#
#*******************************************************************
function Show-Usage()
{
$usage = @'
Get-TimeZone.ps1
This script is used to get time zone information.

Usage:
Get-TimeZone.ps1 <-help | -list>

Parameters:

    -help
     Displays usage information.

    -list
     Lists the information for the time zones found in HKEY_LOCAL_MACHINE\
     SOFTWARE\Microsoft\Windows NT\CurrentVersion\Time Zones.

Examples:
    Get-TimeZone.ps1
    Get-TimeZone.ps1 -list
    Get-TimeZone.ps1 -help
'@

    $usage
}


#*******************************************************************
# Function Process-Arguments()
#
# Purpose: To validate parameters and their values
#
# Input:   All parameters
#
# Output:  Exit script if parameters are invalid
#
#*******************************************************************
function Process-Arguments()
{
    ## Write-host 'Processing Arguments'

    if ($unnamedArgs.Length -gt 0)
    {
        write-host "The following arguments are not defined:"
        $unnamedArgs
    }

    if ($help -eq $true) 
    { 
        Show-Usage
        break
    }

    if ($list -eq $true) 
    { 
        
        Get-TimeZonesInRegistry($name)
        break
    }
    else
    { 
        Get-TimeZone
        break
    }
}


#*******************************************************************
# Main Script
#*******************************************************************

## Compile our C# code
Compile-CSharp $timeZoneCSharpCode

Process-Arguments
