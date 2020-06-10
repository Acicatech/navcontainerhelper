﻿<# 
 .Synopsis
  Flush Caches used in ContainerHelper
 .Description
  Extract all files from a Container Image necessary to start a generic container with these files
 .Parameter cache
  Specify which cache you want to flush (default is all)
  - calSourceCache is the C/AL Source Cache
  - alSourceCache is the AL Source Cache
  - filesCache is the files extracted from other images
  - applicationCache are the test applications runtime cache (15.x containers)
  - bakFolderCache are version specific backup sets
 .Example
  Flush-ContainerHelperCache -cache calSourceCache
#>
function Flush-ContainerHelperCache {
    [CmdletBinding()]
    Param (
        [ValidateSet('all','calSourceCache','alSourceCache','applicationCache','bakFolderCache','filesCache','bcartifacts')]
        [string] $cache = 'all'
    )

    $folders = @()
    if ($cache -eq 'all' -or $cache -eq 'calSourceCache') {
        $folders += @("extensions\original-*-??","extensions\original-*-??-newsyntax")
    }

    if ($cache -eq 'all' -or $cache -eq 'filesCache') {
        $folders += @("*-??-files")
    }

    if ($cache -eq 'all' -or $cache -eq 'bcartifacts') {
        Get-ChildItem -Path 'c:\bcartifacts.cache' | ?{ $_.PSIsContainer } | ForEach-Object {
            Write-Host "Removing Cache $($_.FullName)"
            [System.IO.Directory]::Delete($_.FullName, $true)
        }
    }

    if ($cache -eq 'all' -or $cache -eq 'alSourceCache') {
        $folders += @("extensions\original-*-??-al")
    }

    if ($cache -eq 'all' -or $cache -eq 'applicationCache') {
        $folders += @("extensions\applications-*-??","extensions\sandbox-applications-*-??","extensions\onprem-applications-*-??")
    }

    if ($cache -eq 'all' -or $cache -eq 'bakFolderCache') {
        $folders += @("sandbox-*-bakfolders","onprem-*-bakfolders")
    }

    $folders | ForEach-Object {
        $folder = Join-Path $hostHelperFolder $_
        Get-Item $folder -ErrorAction SilentlyContinue | ?{ $_.PSIsContainer } | ForEach-Object {
            Write-Host "Removing Cache $($_.FullName)"
            [System.IO.Directory]::Delete($_.FullName, $true)
        }
    }
}
Export-ModuleMember -Function Flush-ContainerHelperCache
