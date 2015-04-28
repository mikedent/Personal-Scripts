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
# File:     CompileCSharpLib.ps1
# Date:     06/03/2009
# Version:  1.0.0
#
# Purpose:  PowerShell script containing Compile-Csharp function.
#
# Usage:    . CompileCSharpLib.ps1
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
# Declare Functions
#*******************************************************************

#*******************************************************************
# Function Compile-Csharp()
#
# Purpose:  Function to on the fly compile C# code
#
# Input:    $code               String containing C# code
#           $FrameworkVersion   .NET Framework version
#           $References         Additional Framework references
#
# Source:  http://blogs.msdn.com/powershell/archive/2006/04/25/583236.aspx
#
#*******************************************************************
function Compile-Csharp ([string] $code, $FrameworkVersion="v2.0.50727", [Array]$References)
{
    #
    # Get an instance of the CSharp code provider
    #
    $cp = new-object Microsoft.CSharp.CSharpCodeProvider

    #
    # Build up a compiler params object...
    $framework = Join-Path $env:windir "Microsoft.NET\Framework\$FrameWorkVersion"
    $refs = New-Object Collections.ArrayList
    $refs.AddRange( @("${framework}\System.dll",
        "${framework}\system.windows.forms.dll",
		"${framework}\System.data.dll",
        "${framework}\System.Drawing.dll",
        "${framework}\System.Xml.dll"))
    if ($references.Count -ge 1)
    {
        $refs.AddRange($References)
    }

    $cpar = New-Object System.CodeDom.Compiler.CompilerParameters
    $cpar.GenerateInMemory = $true
    $cpar.GenerateExecutable = $false
    # $cpar.OutputAssembly = "custom"
    $cpar.ReferencedAssemblies.AddRange($refs)
    $cr = $cp.CompileAssemblyFromSource($cpar, $code)

    if ( $cr.Errors.Count)
    {
        $codeLines = $code.Split("`n");
        foreach ($ce in $cr.Errors)
        {
            write-host "Error: $($codeLines[$($ce.Line - 1)])"
            $ce |out-default
        }
        Throw "INVALID DATA: Errors encountered while compiling code"
    }
}

