﻿<# 
 .Synopsis
  Backup databases in a NAV/BC Container as .bak files
 .Description
  If the Container is multi-tenant, this command will create an app.bak and a tenant.bak (or multiple tenant.bak files)
  If the Container is single-tenant, this command will create one .bak file called database.bak.
 .Parameter containerName
  Name of the container for which you want to export and convert objects
 .Parameter sqlCredential
  Credentials for the SQL admin user if using NavUserPassword authentication.
 .Parameter Folder
  The folder to which the bak files are exported (needs to be shared with the container)
 .Parameter tenant
  The tenant database(s) to export, only applies to multi-tenant containers
  Omit to export tenant template, specify default to export the default tenant.
 .Example
  Backup-NavContainerDatabases -containerName test
 .Example
  Backup-NavContainerDatabases -containerName test -bakfolder "c:\programdata\navcontainerhelper\extensions\test"
 .Example
  Backup-NavContainerDatabases -containerName test -bakfolder "c:\demo" -sqlCredential <sqlCredential>
 .Example
  Backup-NavContainerDatabases -containerName test -tenant default
 .Example
  Backup-NavContainerDatabases -containerName test -tenant @("default","tenant")
#>
function Backup-NavContainerDatabases {
    Param(
        [string] $containerName = "navserver", 
        [PSCredential] $sqlCredential = $null,
        [string] $bakFolder = "",
        [string[]] $tenant = @("tenant")
    )

    $sqlCredential = Get-DefaultSqlCredential -containerName $containerName -sqlCredential $sqlCredential -doNotAskForCredential

    $containerFolder = Join-Path $ExtensionsFolder $containerName
    if ("$bakFolder" -eq "") {
        $bakFolder = $containerFolder
    }
    $containerBakFolder = Get-NavContainerPath -containerName $containerName -path $bakFolder -throw

    Invoke-ScriptInNavContainer -containerName $containerName -ScriptBlock { Param([System.Management.Automation.PSCredential]$sqlCredential, $bakFolder, $tenant)
       
        function Backup {
            Param(
                [string]$serverInstance,
                [string]$database,
                [string]$bakFolder,
                [string]$bakName
            )
            $bakFile = Join-Path $bakFolder "$bakName.bak"
            if (Test-Path $bakFile) {
                Remove-Item -Path $bakFile -Force
            }
            Backup-SqlDatabase -ServerInstance $serverInstance -database $database -BackupFile $bakFile
        }

        $customConfigFile = Join-Path (Get-Item "C:\Program Files\Microsoft Dynamics NAV\*\Service").FullName "CustomSettings.config"
        [xml]$customConfig = [System.IO.File]::ReadAllText($customConfigFile)
        $multitenant = ($customConfig.SelectSingleNode("//appSettings/add[@key='Multitenant']").Value -eq "true")
        $databaseServer = $customConfig.SelectSingleNode("//appSettings/add[@key='DatabaseServer']").Value
        $databaseInstance = $customConfig.SelectSingleNode("//appSettings/add[@key='DatabaseInstance']").Value
        $databaseName = $customConfig.SelectSingleNode("//appSettings/add[@key='DatabaseName']").Value

        $databaseServerInstance = $databaseServer
        if ("$databaseInstance" -ne "") {
            $databaseServerInstance = "$databaseServer\$databaseInstance"
        }

        if (!(Test-Path $bakFolder)) {
            New-Item $bakFolder -ItemType Directory | Out-Null
        }

        if ($multitenant) {
            Backup -ServerInstance $databaseServerInstance -database $DatabaseName -bakFolder $bakFolder -bakName "app"
            $tenant | ForEach-Object {
                Backup -ServerInstance $databaseServerInstance -database $_ -bakFolder $bakFolder -bakName $_
            }
        } else {
            Backup -ServerInstance $databaseServerInstance -database $DatabaseName -bakFolder $bakFolder -bakName "database"
        }
    } -ArgumentList $sqlCredential, $containerbakFolder, $tenant
}
Set-Alias -Name Backup-BCContainerDatabases -Value Backup-NavContainerDatabases
Export-ModuleMember -Function Backup-NavContainerDatabases -Alias Backup-BCContainerDatabases
