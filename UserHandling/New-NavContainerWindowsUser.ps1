﻿<# 
 .Synopsis
  Creates a new Winodws User in a NAV/BC Container
 .Description
  Creates a new Windows user in a NAV/BC Container.
 .Parameter containerName
  Name of the container in which you want to create a windows user
 .Parameter Credential
  Credentials of the new Winodws user
 .Parameter group
  Name of the local group to add the user to (default is administrators)
 .Example
  New-NavContainerWindowsUser -containerName test -tenantId mytenant -username freddyk -password $password
#>
function New-NavContainerWindowsUser {
    Param
    (
        [Parameter(Mandatory=$false)]
        [string] $containerName = "navserver",
        [Parameter(Mandatory=$true)]
        [PSCredential] $Credential,
        [parameter(Mandatory=$false)]        
        [string] $group = "administrators"
    )

    PROCESS
    {
        Invoke-ScriptInNavContainer -containerName $containerName -ScriptBlock { param([System.Management.Automation.PSCredential]$Credential, [string]$group)

            Write-Host "Creating Windows user $($Credential.username)"
            New-LocalUser -AccountNeverExpires -FullName $Credential.username -Name $Credential.username -Password $Credential.Password | Out-Null
            Write-Host "Adding Windows user $($Credential.username) to $group"
            Add-LocalGroupMember -Group $group -Member $Credential.username -ErrorAction Ignore
                        
        } `
        -ArgumentList $Credential, $group
    }
}
Set-Alias -Name New-BCContainerWindowsUser -Value New-NavContainerWindowsUser
Export-ModuleMember -Function New-NavContainerWindowsUser -Alias New-BCContainerWindowsUser
