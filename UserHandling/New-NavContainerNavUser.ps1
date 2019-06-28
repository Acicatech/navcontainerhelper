﻿<# 
 .Synopsis
  Creates a new User in a NAV/BC Container
 .Description
  Creates a new user in a NAV/BC container.
  If the Container is multitenant, the user will be added to a specified tenant
 .Parameter containerName
  Name of the container in which you want to create the user (default navserver)
 .Parameter tenant
  Name of tenant in which you want to create a user
 .Parameter Credential
  Credentials of the new user (if using NavUserPassword authentication)
 .Parameter WindowsAccount
  WindowsAccount of the new user (if using Windows authentication)
 .Parameter AuthenticationEmail
  AuthenticationEmail of the new user
 .Parameter ChangePasswordAtNextLogOn
  Switch to indicate that the user needs to change password at next login (if using NavUserPassword authentication)
 .Parameter PermissionSetId
  Name of the permissionSetId to assign to the user (default is SUPER)
 .Example
  New-NavContainerNavUser -containerName test -tenantId mytenant -credential $credential
 .Example
  New-NavContainerNavUser -containerName test -tenantId mytenant -WindowsAccount freddyk -PermissionSetId SUPER
#>
function New-NavContainerNavUser {
    Param
    (
        [Parameter(Mandatory=$false)]
        [string]$containerName = "navserver",
        [Parameter(Mandatory=$false)]
        [string]$tenant = "default",
        [parameter(Mandatory=$true, ParameterSetName="NavUserPassword")]
        [System.Management.Automation.PSCredential]$Credential,
        [parameter(Mandatory=$true, ParameterSetName="Windows")]
        [string]$WindowsAccount,
        [parameter(Mandatory=$false, ParameterSetName="NavUserPassword")]
        [string]$AuthenticationEmail,
        [parameter(Mandatory=$false, ParameterSetName="NavUserPassword")]
        [bool]$ChangePasswordAtNextLogOn = $true,
        [parameter(Mandatory=$false)]        
        [string]$PermissionSetId = "SUPER"
    )

    PROCESS
    {
        Invoke-ScriptInNavContainer -containerName $containerName -ScriptBlock { param([System.Management.Automation.PSCredential]$Credential, [string]$Tenant, [string]$WindowsAccount, [string]$AuthenticationEMail, [bool]$ChangePasswordAtNextLogOn, [string]$PermissionSetId)
                        
            $TenantParam = @{}
            if ($Tenant) {
                $TenantParam.Add('Tenant', $Tenant)
            }
            $Parameters = @{}
            if ($AuthenticationEMail) {
                $Parameters.Add('AuthenticationEmail',$AuthenticationEmail)
            }
            if($WindowsAccount) {
                Write-Host "Creating User for WindowsAccount $WindowsAccount"
      			New-NAVServerUser -ServerInstance $ServerInstance @TenantParam -WindowsAccount $WindowsAccount @Parameters
                Write-Host "Assigning Permission Set $PermissionSetId to $WindowsAccount"
                New-NavServerUserPermissionSet -ServerInstance $ServerInstance @tenantParam -WindowsAccount $WindowsAccount -PermissionSetId $PermissionSetId
            } else {
                Write-Host "Creating User $($Credential.UserName)"
                if ($ChangePasswordAtNextLogOn) {
      			    New-NAVServerUser -ServerInstance $ServerInstance @TenantParam -Username $Credential.UserName -Password $Credential.Password -ChangePasswordAtNextLogon @Parameters
                } else {
      			    New-NAVServerUser -ServerInstance $ServerInstance @TenantParam -Username $Credential.UserName -Password $Credential.Password @Parameters
                }
                Write-Host "Assigning Permission Set $PermissionSetId to $($Credential.Username)"
                New-NavServerUserPermissionSet -ServerInstance $ServerInstance @tenantParam -username $Credential.username -PermissionSetId $PermissionSetId
            }
        } `
        -ArgumentList $Credential, $Tenant, $WindowsAccount, $AuthenticationEMail, $ChangePasswordAtNextLogOn, $PermissionSetId
    }
}
Set-Alias -Name New-BCContainerBCUser -Value New-NavContainerNavUser
Export-ModuleMember -Function New-NavContainerNavUser -Alias New-BCContainerBCUser
