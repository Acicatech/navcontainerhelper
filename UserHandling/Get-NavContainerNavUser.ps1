﻿<# 
 .Synopsis
  Get list of users from NAV/BC Container
 .Description
  Retrieve the list of user objects from a tenant in a NAV/BC Container
 .Parameter containerName
  Name of the container from which you want to get the users (default navserver)
 .Parameter tenant
  Name of tenant from which you want to get the users
 .Example
  Get-NavContainerNavUser
 .Example
  Get-NavContainerNavUser -containerName test -tenant mytenant
#>
function Get-NavContainerNavUser {
Param
    (
        [Parameter(Mandatory=$false)]
        [string]$containerName = "navserver",
        [Parameter(Mandatory=$false)]
        [string]$tenant = "default"
    )

    PROCESS
    {
        Invoke-ScriptInNavContainer -containerName $containerName -ScriptBlock { param($tenant)
            Get-NavServerUser -ServerInstance $ServerInstance -tenant $tenant
        } -ArgumentList $tenant | Where-Object {$_ -isnot [System.String]}
    }
}
Set-Alias -Name Get-BCContainerBCUser -Value Get-NavContainerNavUser
Export-ModuleMember -Function Get-NavContainerNavUser -Alias Get-BCContainerBCUser
