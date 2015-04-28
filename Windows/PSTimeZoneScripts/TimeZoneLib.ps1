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
# File:     TimeZoneLib.ps1
# Date:     06/06/2009
# Version:  1.0.1
#
# Purpose:  PowerShell script containing functions used by Set-TimeZone.ps1
#           and Get-TimeZone.ps1.
#
# Usage:    . TimeZoneLib.ps1
#
# Requires: CompileCSharpLib.ps1, TimeZoneCSharp.ps1
#
# Used by:  Set-TimeZone.ps1, Get-TimeZone.ps1
#
# Copyright (C) 2009 Microsoft Corporation
#
#
# Revisions:
# ----------
# 1.0.0   06/03/2009   Created script.
# 1.0.1   06/06/2009   Fixed bug - No longer setting timeZoneInfo.standardDate
#                      and $timeZoneInfo.daylightDate when 
#                      $timeZoneInfo.dynamicDaylightTimeDisabled = $true.
#
#******************************************************************************

#*******************************************************************
# Declare Global Variables and Constants
#*******************************************************************

# Define constants
set-variable SE_CREATE_TOKEN_NAME "SeCreateTokenPrivilege" -option constant
set-variable SE_ASSIGNPRIMARYTOKEN_NAME "SeAssignPrimaryTokenPrivilege" -option constant
set-variable SE_LOCK_MEMORY_NAME "SeLockMemoryPrivilege" -option constant
set-variable SE_INCREASE_QUOTA_NAME "SeIncreaseQuotaPrivilege" -option constant
set-variable SE_UNSOLICITED_INPUT_NAME "SeUnsolicitedInputPrivilege" -option constant
set-variable SE_MACHINE_ACCOUNT_NAME "SeMachineAccountPrivilege" -option constant
set-variable SE_TCB_NAME "SeTcbPrivilege" -option constant
set-variable SE_SECURITY_NAME "SeSecurityPrivilege" -option constant
set-variable SE_TAKE_OWNERSHIP_NAME "SeTakeOwnershipPrivilege" -option constant
set-variable SE_LOAD_DRIVER_NAME "SeLoadDriverPrivilege" -option constant
set-variable SE_SYSTEM_PROFILE_NAME "SeSystemProfilePrivilege" -option constant
set-variable SE_SYSTEMTIME_NAME "SeSystemtimePrivilege" -option constant
set-variable SE_PROF_SINGLE_PROCESS_NAME "SeProfileSingleProcessPrivilege" -option constant
set-variable SE_INC_BASE_PRIORITY_NAME "SeIncreaseBasePriorityPrivilege" -option constant
set-variable SE_CREATE_PAGEFILE_NAME "SeCreatePagefilePrivilege" -option constant
set-variable SE_CREATE_PERMANENT_NAME "SeCreatePermanentPrivilege" -option constant
set-variable SE_BACKUP_NAME "SeBackupPrivilege" -option constant
set-variable SE_RESTORE_NAME "SeRestorePrivilege" -option constant
set-variable SE_SHUTDOWN_NAME "SeShutdownPrivilege" -option constant
set-variable SE_DEBUG_NAME "SeDebugPrivilege" -option constant
set-variable SE_AUDIT_NAME "SeAuditPrivilege" -option constant
set-variable SE_SYSTEM_ENVIRONMENT_NAME "SeSystemEnvironmentPrivilege" -option constant
set-variable SE_CHANGE_NOTIFY_NAME "SeChangeNotifyPrivilege" -option constant
set-variable SE_REMOTE_SHUTDOWN_NAME "SeRemoteShutdownPrivilege" -option constant
set-variable SE_UNDOCK_NAME "SeUndockPrivilege" -option constant
set-variable SE_SYNC_AGENT_NAME "SeSyncAgentPrivilege" -option constant
set-variable SE_ENABLE_DELEGATION_NAME "SeEnableDelegationPrivilege" -option constant
set-variable SE_MANAGE_VOLUME_NAME "SeManageVolumePrivilege" -option constant
set-variable SE_IMPERSONATE_NAME "SeImpersonatePrivilege" -option constant
set-variable SE_CREATE_GLOBAL_NAME "SeCreateGlobalPrivilege" -option constant
set-variable SE_TRUSTED_CREDMAN_ACCESS_NAME "SeTrustedCredManAccessPrivilege" -option constant
set-variable SE_RELABEL_NAME "SeRelabelPrivilege" -option constant
set-variable SE_INC_WORKING_SET_NAME "SeIncreaseWorkingSetPrivilege" -option constant
set-variable SE_TIME_ZONE_NAME "SeTimeZonePrivilege" -option constant
set-variable SE_CREATE_SYMBOLIC_LINK_NAME "SeCreateSymbolicLinkPrivilege" -option constant

# Initialize variables
$timeZonesKey = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Time Zones\"
$timeZonesKeyDrive = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Time Zones\"


#*******************************************************************
# Declare Functions
#*******************************************************************

#*******************************************************************
# Function Get-CalendarDateFromTziTransitionDate()
#
# Purpose:  Converts the SYSTEM_TIME transition dates from a time
#           zone TZI (REG_TZI_FORMAT) value to a current year date
#
# Input:    $tziDate     SYSTEM_TIME transition date
#
# Returns:  calendar date for tranition or 1 Jan 1900 if tranition
#           date is not defined
#
#*******************************************************************
function Get-CalendarDateFromTziTransitionDate([NSTimeZone.SYSTEM_TIME] $tziDate)
{
    $year = (get-date).year

    if ($tziDate.month -eq 0) 
    {
        ## Transition date not defined - return 1900 Jan 1
        $retVal = get-date -y 1900 -mo 1 -day 1 -h 0 -mi 0 -s 0
    }
    else
    {
        if ($tziDate.day -lt 5)
        {
            $firstWeekday = (get-date -y $year -mo $tziDate.month -day 1 -h 0 -mi 0 -s 0).DayOfWeek.Value
            $tempDay = (($tziDate.dayOfWeek - $firstWeekday) + ($tziDate.day - 1) * 7) + 1
            $tempDate = (get-date -y $year -mo $tziDate.month -day $tempDay -h 0 -mi 0 -s 0)
        }
        else
        {
            $tempDate = (get-date -y $year -mo ($tziDate.month + 1) -day 1 -h 0 -mi 0 -s 0).AddDays(-1)
            $lastWeekday = $tempDate.DayOfWeek.Value
            $tempDate = $tempDate.AddDays(($tziDate.dayOfWeek - ($lastWeekday) - 7) % 7)
        }
        $retVal = $tempDate.AddHours($tziDate.hour).AddMinutes($tziDate.minute).AddSeconds($tziDate.second)
    }
    $retVal
}


#*******************************************************************
# Function Set-Timezone()
#
# Purpose:  Sets the current time zone.
#
# Input:    $name  The Registry Key name for the time zone found in 
#                  HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\
#                  CurrentVersion\Time Zones.
#
#*******************************************************************
function Set-Timezone($tzName)
{
    $searchKey = $timeZonesKey + $tzName

    $foundMatch = $false
    ## Go through each item in the registry
    foreach($item in Get-ChildItem $timeZonesKeyDrive -ErrorAction SilentlyContinue)
    {
        ## Check if the key name matches
        if($item.Name -eq $searchKey)
        {
            $matchKey = $item
            $foundMatch = $true
        }
    }

    if ($foundMatch) 
    {
        ## write-host $matchKey.Name

        $strComputer = "."
        $colItems = get-wmiobject -class "Win32_OperatingSystem" -namespace "root\CIMV2" -computername $strComputer
        foreach ($objItem in $colItems) {
              $buildNumber = $objItem.BuildNumber
        }
        
        $keyProperties = Get-ItemProperty $matchKey.PsPath

        $regTzi = [NSTimeZone.TimeZoneControl]::GetRegTziFormat($keyProperties.TZI)
        #write-host "Setting time zone to ""$($keyProperties.Std)""."

        If ($buildNumber -ge 6000) 
        {
            $timeZoneInfo = New-Object NSTimeZone.DYNAMIC_TIME_ZONE_INFORMATION
            $timeZoneInfo.bias = $regTzi.Bias
            $timeZoneInfo.standardBias = $regTzi.standardBias
            $timeZoneInfo.daylightBias = $regTzi.daylightBias
            $timeZoneInfo.standardName = $keyProperties.MUI_Std
            $timeZoneInfo.daylightName = $keyProperties.MUI_Dlt
            $timeZoneInfo.timeZoneKeyName = $tzName
            if ($dstoff -eq $false) {
                $timeZoneInfo.standardDate = $regTzi.standardDate
                $timeZoneInfo.daylightDate = $regTzi.daylightDate
                $timeZoneInfo.dynamicDaylightTimeDisabled = $false
            } else { 
                #write-host "(dynamic daylight savings time disabled)"
                $timeZoneInfo.dynamicDaylightTimeDisabled = $true
            }
            $retVal = [NSPrivs.TokenPrivileges]::EnablePrivilege($SE_TIME_ZONE_NAME)
            [NSTimeZone.TimeZoneControl]::SetDynamicTimeZone($timeZoneInfo)
            $retVal = [NSPrivs.TokenPrivileges]::DisablePrivilege($SE_TIME_ZONE_NAME)
        }
        else
        {
            $timeZoneInfo = New-Object NSTimeZone.TIME_ZONE_INFORMATION
            $timeZoneInfo.bias = $regTzi.Bias
            $timeZoneInfo.standardBias = $regTzi.standardBias
            $timeZoneInfo.daylightBias = $regTzi.daylightBias
            $timeZoneInfo.standardDate = $regTzi.standardDate
            $timeZoneInfo.daylightDate = $regTzi.daylightDate
            $timeZoneInfo.standardName = $keyProperties.Std
            $timeZoneInfo.daylightName = $keyProperties.Dlt
            [NSTimeZone.TimeZoneControl]::SetTimeZone($timeZoneInfo)
        }
    }
    else
    {
        write-Error "Time zone not found: $tzName" 2>&1 | Out-Null
    }
}


#*******************************************************************
# Function Get-TimeZonesInRegistry()
#
# Purpose:  Lists the information for time zones found in 
#           HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\
#           CurrentVersion\Time Zones.
#
#*******************************************************************
function Get-TimeZonesInRegistry()
{
    foreach($item in Get-ChildItem $timeZonesKeyDrive -ErrorAction SilentlyContinue)
    {
        $leafName = Split-Path -leaf $item.Name
        write-host "[$leafName]"
                
        $keyProperties = Get-ItemProperty $item.PsPath

        foreach($property in (Get-ItemProperty $item.PsPath).PsObject.Properties)
        {
        ## Add MUI_* value handling via http://blogs.msdn.com/michkap/archive/2006/10/24/867880.aspx
        switch ($property.Name)
            { 
                "PSPath"
                {
                    ## Skip the property if it was one PowerShell added
                    continue
                }
                "PSChildName"
                {
                    ## Skip the property if it was one PowerShell added
                    continue
                }
                "PSParentPath" 
                {
                    ## Skip the property if it was one PowerShell added
                    continue
                }
                "PSProvider" 
                {
                    ## Skip the property if it was one PowerShell added
                    continue
                }
                "MUI_Display" 
                {
                    ## $keyPath = $item -replace 'HKEY_LOCAL_MACHINE\\', ''
                    ## $muiDisplay = [RegMUI.RegMUIClass]::GetRegMUIValue("HKEY_LOCAL_MACHINE","$($keyPath)","MUI_Display")
                    $muiDisplay = [NSMui.MUIString]::GetIndirectString($keyProperties.MUI_Display)
                    write-host "MUI_Display=$($muiDisplay)"
                    continue
                }
                "MUI_Std" 
                {
                    $muiStd = [NSMui.MUIString]::GetIndirectString($keyProperties.MUI_Std)
                    write-host "MUI_Std=$($muiStd)"
                    continue
                }
                "MUI_Dlt" 
                {
                    $muiDlt = [NSMui.MUIString]::GetIndirectString($keyProperties.MUI_Dlt)
                    write-host "MUI_Dlt=$($muiDlt)"
                    continue
                }
                "TZI" 
                {
                     ## Skip the property if it was one PowerShell added
                    $regTzi = [NSTimeZone.TimeZoneControl]::GetRegTziFormat($keyProperties.TZI)
                    write-host "Bias=$($regTzi.Bias)"
                    write-host "StandardBias=$($regTzi.StandardBias)"
                    write-host "DaylightBias=$($regTzi.DaylightBias)"
                    $standardDate = $regTzi.standardDate
                    $daylightDate = $regTzi.daylightDate

                    $calendarStandardDate = Get-CalendarDateFromTziTransitionDate($standardDate)
                    $calendarDaylightDate = Get-CalendarDateFromTziTransitionDate($daylightDate)
                    if ($calendarStandardDate.year -eq 1900)
                    {
                        write-host "StandardDate=(not defined)"
                        write-host "DaylightDate=(not defined)"
                    }
                    else
                    {
                        write-host "StandardDate=$($calendarStandardDate.DateTime)"
                        write-host "DaylightDate=$($calendarDaylightDate.DateTime)"
                    }
                    break
                }
                default 
                {
                    $propertyText = "$($property.Name)=$($property.Value)"
                    $propertyText
                    break
                }
            }
        }
        write-host ""
    }
}


#*******************************************************************
# Function Get-TimeZone()
#
# Purpose:  Gets the current time zone information.
#
#*******************************************************************
function Get-TimeZone()
{
    $strComputer = "."
    $colItems = get-wmiobject -class "Win32_OperatingSystem" -namespace "root\CIMV2" -computername $strComputer
    foreach ($objItem in $colItems) {
          $buildNumber = $objItem.BuildNumber
    }

    write-host "Current time zone information"
    write-host "-----------------------------"

    If ($buildNumber -ge 6000) 
    {
        $timeZoneInfo = [NSTimeZone.TimeZoneControl]::GetDynamicTimeZone()
        write-host "StandardName=$($timeZoneInfo.standardName)"
        write-host "DaylightName=$($timeZoneInfo.daylightName)"
        write-host "Bias=$($timeZoneInfo.Bias)"
        write-host "StandardBias=$($timeZoneInfo.StandardBias)"
        write-host "DaylightBias=$($timeZoneInfo.DaylightBias)"
        $calendarStandardDate = Get-CalendarDateFromTziTransitionDate($timeZoneInfo.standardDate)
        write-host "StandardDate=$($calendarStandardDate.DateTime)"
        $calendarDaylightDate = Get-CalendarDateFromTziTransitionDate($timeZoneInfo.daylightDate)
        write-host "DaylightDate=$($calendarDaylightDate.DateTime)"
        write-host "DynamicDaylightTimeDisabled=$($timeZoneInfo.dynamicDaylightTimeDisabled)"
    }
    else
    {
        $timeZoneInfo = [NSTimeZone.TimeZoneControl]::GetTimeZone()
        write-host "StandardName=$($timeZoneInfo.standardName)"
        write-host "DaylightName=$($timeZoneInfo.daylightName)"
        write-host "Bias=$($timeZoneInfo.Bias)"
        write-host "StandardBias=$($timeZoneInfo.StandardBias)"
        write-host "DaylightBias=$($timeZoneInfo.DaylightBias)"
        $calendarStandardDate = Get-CalendarDateFromTziTransitionDate($timeZoneInfo.standardDate)
        write-host "StandardDate=$($calendarStandardDate.DateTime)"
        $calendarDaylightDate = Get-CalendarDateFromTziTransitionDate($timeZoneInfo.daylightDate)
        write-host "DaylightDate=$($calendarDaylightDate.DateTime)"
    }
}

