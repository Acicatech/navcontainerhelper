﻿<# 
 .Synopsis
  Convert txt and delta files to AL
 .Description
  Convert objects in myDeltaFolder to AL. Page and Table extensions are created as new objects using the startId as object Id offset.
  Code modifications and other things not supported in extensions will not be converted to AL.
  Manual modifications are required after the conversion.
 .Parameter containerName
  Name of the container in which the txt2al tool will be executed
 .Parameter myDeltaFolder
  Folder containing delta files
 .Parameter myAlFolder
  Folder in which the AL files are created
 .Parameter startId
  Starting offset for objects created by the tool (table and page extensions)
 .Example
  Convert-Txt2Al -containerName test -mydeltaFolder c:\programdata\navcontainerhelper\mydeltafiles -myAlFolder c:\programdata\navcontainerhelper\myAlFiles -startId 50100
#>
function Convert-Txt2Al {
    Param(
        [Parameter(Mandatory=$true)]
        [string] $containerName, 
        [Parameter(Mandatory=$true)]
        [string] $myDeltaFolder, 
        [Parameter(Mandatory=$true)]
        [string] $myAlFolder, 
        [int] $startId=50100,
        [string] $dotNetAddInsPackage
    )

    AssumeNavContainer -containerOrImageName $containerName -functionName $MyInvocation.MyCommand.Name

    $containerMyDeltaFolder = Get-NavContainerPath -containerName $containerName -path $myDeltaFolder -throw
    $containerMyAlFolder = Get-NavContainerPath -containerName $containerName -path $myAlFolder -throw
    $containerDotNetAddInsPackage = ""
    if ($dotNetAddInsPackage) {
        $containerDotNetAddInsPackage = Get-NavContainerPath -containerName $containerName -path $dotNetAddInsPackage -throw
    }

    $navversion = Get-NavContainerNavversion -containerOrImageName $containerName
    $version = [System.Version]($navversion.split('-')[0])
    $ignoreSystemObjects = ($version.Major -ge 14)

    $dummy = Invoke-ScriptInNavContainer -containerName $containerName -ScriptBlock { Param($myDeltaFolder, $myAlFolder, $startId, $dotNetAddInsPackage)
        
        $erroractionpreference = 'Continue'

        if (!($txt2al)) {
            throw "You cannot run Convert-Txt2Al on this Container"
        }
        Write-Host "Converting files in $myDeltaFolder to .al files in $myAlFolder with startId $startId (container paths)"
        Remove-Item -Path $myAlFolder -Recurse -Force -ErrorAction Ignore
        New-Item -Path $myAlFolder -ItemType Directory -ErrorAction Ignore | Out-Null

        $txt2alParameters = @("--source=""$myDeltaFolder""", "--target=""$myAlFolder""", "--rename", "--extensionStartId=$startId")
        if ($dotNetAddInsPackage) {
            $txt2alParameters += @("--dotNetAddInsPackage=""$dotNetAddInsPackage""")
        }

        Write-Host "txt2al.exe $([string]::Join(' ', $txt2alParameters))"
        & $txt2al $txt2alParameters 2> $null

        $erroractionpreference = 'Stop'

    } -ArgumentList $containerMyDeltaFolder, $containerMyAlFolder, $startId, $containerDotNetAddInsPackage
}
Export-ModuleMember -Function Convert-Txt2Al
