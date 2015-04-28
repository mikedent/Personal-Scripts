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
# File:     TimeZoneCSharp.ps1
# Date:     06/03/2009
# Version:  1.0.0
#
# Purpose:  PowerShell script containing here-string with C# code required by
#           Set-TimeZone.ps1 and Get-TimeZone.ps1.
#
# Usage:    . TimeZoneCSharp.ps1
#
# Requires: CompileCSharpLib.ps1, TimeZoneLib.ps1
#
# Used by:  Set-TimeZone.ps1, Get-TimeZone.ps1
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
# Declare Global Variables and Constants
#*******************************************************************

$timeZoneCSharpCode = @'
using System;
using System.Text;
using System.Runtime.InteropServices;
using Microsoft.Win32; 

namespace NSTimeZone
{
    public class TimeZoneControl {
        [DllImport("kernel32.dll", CharSet = CharSet.Auto)]
        private static extern int GetTimeZoneInformation(out TIME_ZONE_INFORMATION lpTimeZoneInformation);

        [DllImport("kernel32.dll", CharSet = CharSet.Auto)]
        private static extern bool SetTimeZoneInformation([In] ref TIME_ZONE_INFORMATION lpTimeZoneInformation);

        [DllImport("kernel32.dll", CharSet = CharSet.Auto)]
        private static extern int GetDynamicTimeZoneInformation(out DYNAMIC_TIME_ZONE_INFORMATION lpTimeZoneInformation);

        [DllImport("kernel32.dll", CharSet = CharSet.Auto)]
        private static extern bool SetDynamicTimeZoneInformation([In] ref DYNAMIC_TIME_ZONE_INFORMATION lpTimeZoneInformation);

        public static void SetTimeZone(TIME_ZONE_INFORMATION tzi) {
            SetTimeZoneInformation(ref tzi);
        }

        public static TIME_ZONE_INFORMATION GetTimeZone() {
            TIME_ZONE_INFORMATION tzi;

            int currentTimeZone = GetTimeZoneInformation(out tzi);

            return tzi;
        }

        public static void SetDynamicTimeZone(DYNAMIC_TIME_ZONE_INFORMATION dtzi) {
            SetDynamicTimeZoneInformation(ref dtzi);
        }

        public static DYNAMIC_TIME_ZONE_INFORMATION GetDynamicTimeZone() {
            DYNAMIC_TIME_ZONE_INFORMATION dtzi;

            int currentTimeZone = GetDynamicTimeZoneInformation(out dtzi);

            return dtzi;
        }

        public static REG_TZI_FORMAT GetRegTziFormat(byte[] tziRegValue) {
            REG_TZI_FORMAT rtzi;

        	object varValue = tziRegValue;
        	byte[] baData = varValue as byte[];
        	int iSize = baData.Length;
        	IntPtr buffer = Marshal.AllocHGlobal(iSize);
        	Marshal.Copy(baData, 0, buffer, iSize);
        	rtzi = (REG_TZI_FORMAT)Marshal.PtrToStructure(buffer,typeof(REG_TZI_FORMAT));
        	Marshal.FreeHGlobal(buffer);
            
            return rtzi;
        }
    }

    [StructLayoutAttribute(LayoutKind.Sequential)]
    public struct SYSTEM_TIME { 
        public short year; 
        public short month; 
        public short dayOfWeek; 
        public short day; 
        public short hour; 
        public short minute; 
        public short second; 
        public short milliseconds;
    }

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct TIME_ZONE_INFORMATION { 
        public int bias;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)]
        public string standardName;
        public SYSTEM_TIME standardDate;
        public int standardBias;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)]
        public string daylightName;
        public SYSTEM_TIME daylightDate;
        public int daylightBias;
    }

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct DYNAMIC_TIME_ZONE_INFORMATION { 
        public int bias;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)]
        public string standardName;
        public SYSTEM_TIME standardDate;
        public int standardBias;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)]
        public string daylightName;
        public SYSTEM_TIME daylightDate;
        public int daylightBias;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)]
        public string timeZoneKeyName;
        public bool dynamicDaylightTimeDisabled;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct REG_TZI_FORMAT { 
        public int bias;
        public int standardBias;
        public int daylightBias;
        public SYSTEM_TIME standardDate;
        public SYSTEM_TIME daylightDate;
    }
}

namespace NSPrivs
{
    public class TokenPrivileges {
        [DllImport("advapi32.dll", CharSet=CharSet.Auto)]
        public static extern int OpenProcessToken(int ProcessHandle, int DesiredAccess, 
        ref int tokenhandle);

        [DllImport("kernel32.dll", CharSet=CharSet.Auto)]
        public static extern int GetCurrentProcess();

        [DllImport("advapi32.dll", CharSet=CharSet.Auto)]
        public static extern int LookupPrivilegeValue(string lpsystemname, string lpname, 
        [MarshalAs(UnmanagedType.Struct)] ref LUID lpLuid);

        [DllImport("advapi32.dll", CharSet=CharSet.Auto)]
        public static extern int AdjustTokenPrivileges(int tokenhandle, int disableprivs, 
        [MarshalAs(UnmanagedType.Struct)]ref TOKEN_PRIVILEGES Newstate, int bufferlength, 
        int PreivousState, int Returnlength);
        
        public const int TOKEN_ASSIGN_PRIMARY = 0x00000001;
        public const int TOKEN_DUPLICATE = 0x00000002;
        public const int TOKEN_IMPERSONATE = 0x00000004;
        public const int TOKEN_QUERY = 0x00000008;
        public const int TOKEN_QUERY_SOURCE = 0x00000010;
        public const int TOKEN_ADJUST_PRIVILEGES = 0x00000020;
        public const int TOKEN_ADJUST_GROUPS = 0x00000040;
        public const int TOKEN_ADJUST_DEFAULT = 0x00000080;
        
        public const UInt32 SE_PRIVILEGE_ENABLED_BY_DEFAULT = 0x00000001;
        public const UInt32 SE_PRIVILEGE_ENABLED = 0x00000002;
        public const UInt32 SE_PRIVILEGE_REMOVED = 0x00000004;
        public const UInt32 SE_PRIVILEGE_USED_FOR_ACCESS = 0x80000000;

        public static bool EnablePrivilege(string privilege) {
            try
            {
                int token=0;
                int retVal=0;

                TOKEN_PRIVILEGES TP = new TOKEN_PRIVILEGES();
                LUID LD = new LUID();

                retVal = OpenProcessToken(GetCurrentProcess(), TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, ref token);
                retVal = LookupPrivilegeValue(null, privilege, ref LD);
                TP.PrivilegeCount = 1;
                TP.Attributes = SE_PRIVILEGE_ENABLED;
                TP.Luid = LD;

                retVal = AdjustTokenPrivileges(token, 0, ref TP, 1024, 0, 0);
                return true;
            }
            catch
            {
                return false;
            }
        }

        public static bool DisablePrivilege(string privilege) {
            try
            {
                int token=0;
                int retVal=0;

                TOKEN_PRIVILEGES TP = new TOKEN_PRIVILEGES();
                LUID LD = new LUID();

                retVal = OpenProcessToken(GetCurrentProcess(), TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, ref token);
                retVal = LookupPrivilegeValue(null, privilege, ref LD);
                TP.PrivilegeCount = 1;
                // TP.Attributes should be none (not set) to disable privilege
                TP.Luid = LD;

                retVal = AdjustTokenPrivileges(token, 0, ref TP, 1024, 0, 0);
                return true;
            }
            catch
            {
                return false;
            }
        }
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct LUID
    {
        public int LowPart;
        public int HighPart;
    } 
    [StructLayout(LayoutKind.Sequential)]
    public struct TOKEN_PRIVILEGES
    {
        public LUID Luid;
        public UInt32 Attributes;
        public UInt32 PrivilegeCount;
    }
}

namespace NSMui 
{
    public class MuiString 
    {
        [DllImport("shlwapi.dll", CharSet=CharSet.Unicode)]
        public static extern int SHLoadIndirectString(string pszSource, StringBuilder pszOutBuf, int cchOutBuf, string ppvReserved);

        public static string GetIndirectString(string indirectString)
        {
            try 
            {
                 string stringRetVal = "";
                 int retval;

                //NOTE: Build the output buffer reference
                StringBuilder lptStr = new StringBuilder(1024);
                //NOTE: indirectString contains the MUI formatted string
                retval = SHLoadIndirectString(indirectString, lptStr, 1024, null);
                if(retval != 0)
                {
                    stringRetVal = "SHLoadIndirectString failed with error " + retval;
                    return stringRetVal;
                }
                else
                {
                    stringRetVal = lptStr.ToString();
                    return stringRetVal;
                }
            }
            catch (Exception ex)
            {
                return "Exception: " + ex.Message;
            }
        }
    }
}
'@