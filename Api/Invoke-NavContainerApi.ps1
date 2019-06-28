﻿<# 
 .Synopsis
  Invoke Api in Container
 .Description
  Invoke an Api in a Container.
 .Parameter containerName
  Name of the container in which you want to invoke an api
 .Parameter tenant
  Name of the tenant in which context you want to invoke an api
 .Parameter CompanyId
  Id the Company in which context you want to invoke an api (Use Get-NavContainerApiCompanyId
 .Parameter Codeunitid
  Id of the codeunit you want to invoke
 .Parameter Credential
  Credentials for the user making invoking the api (do not specify if using Windows auth)
 .Parameter APIPublisher
  Publisher of the custom api you want to invoke (empty for built in api)
 .Parameter APIGroup
  Group of the custom api you want to invoke (empty for built in api)
 .Parameter APIVersion
  Version of the API you want to invoke (beta, v1.0, ...)
 .Parameter Method
  API Method to invoke (GET, POST, PATCH, DELETE)
 .Parameter Query
  API Query (ex. salesInvoices?$filter=totalAmountIncludingTax gt 10000)
 .Parameter headers
  Additional headers for the api (example: @{ "If-Match" = $etag } )
 .Parameter body
  Parameters for the api (example: @{ "name" = "The Name"; "phoneNumber" = "12 34 56 78" })
 .Example
  $result = Invoke-NavContainerApi -containerName $containerName -tenant $tenant -APIVersion "beta" -Query "companies?`$filter=$companyFilter" -credential $credential
 .Example
  Invoke-NavContainerApi -containerName $containerName -CompanyId $companyId -APIVersion "beta" -Query "customers" -credential $credential | Select-Object -ExpandProperty value
 .Example 
  Invoke-NavContainerApi -containerName $containerName -CompanyId $companyId -APIVersion "beta" -Query "customers?`$filter=$([Uri]::EscapeDataString("number eq '10000'"))" -credential $credential | Select-Object -ExpandProperty value
 .Example
  Invoke-NavContainerApi -containerName $containerName -CompanyId $companyId -APIVersion "beta" -Query "salesInvoices?`$filter=$([Uri]::EscapeDataString("status eq 'Open' and totalAmountExcludingTax gt 1000.00"))" -credential $credential | Select-Object -ExpandProperty value
#>
function Invoke-NavContainerApi {
    Param(
        [Parameter(Mandatory=$true)]
        [string]$containerName, 
        [Parameter(Mandatory=$false)]
        [string]$tenant = "default",
        [Parameter(Mandatory=$false)]
        [string]$CompanyId,
        [Parameter(Mandatory=$false)]
        [System.Management.Automation.PSCredential]$credential = $null,
        [Parameter(Mandatory=$false)]
        [string]$APIPublisher = "",
        [Parameter(Mandatory=$false)]
        [string]$APIGroup = "",
        [Parameter(Mandatory=$true)]
        [string]$APIVersion,
        [Parameter(Mandatory=$false)]
        [string]$Method = "GET",
        [Parameter(Mandatory=$false)]
        [string]$Query,
        [Parameter(Mandatory=$false)]
        [hashtable]$headers = @{},
        [Parameter(Mandatory=$false)]
        [hashtable]$body = $null
    )

    $customConfig = Get-NavContainerServerConfiguration -ContainerName $containerName

    $parameters = @{}
    if ($customConfig.ClientServicesCredentialType -eq "Windows") {
        $parameters += @{ "usedefaultcredential" = $true }
    }
    else {
        if (!($credential)) {
            throw "You need to specify credentials when you are not using Windows Authentication"
        }
        $parameters += @{ "credential" = $credential }
    }

    $serverInstance = $customConfig.ServerInstance

    if ($customConfig.ODataServicesSSLEnabled -eq "true") {
        $protocol = "https://"
    } else {
        $protocol = "http://"
    }
    
    $ip = Get-NavContainerIpAddress -containerName $containerName
    if ($ip) {
        $url = "${protocol}${ip}:$($customConfig.ODataServicesPort)/$($customConfig.ServerInstance)/api"
    }
    else {
        $url = $customconfig.PublicODataBaseUrl.Replace("/OData","/api")
    }

    $sslVerificationDisabled = ($protocol -eq "https://")
    if ($sslVerificationDisabled) {
        if (-not ([System.Management.Automation.PSTypeName]"SslVerification").Type)
        {
            Add-Type -TypeDefinition "
                using System.Net.Security;
                using System.Security.Cryptography.X509Certificates;
                public static class SslVerification
                {
                    private static bool ValidationCallback(object sender, X509Certificate certificate, X509Chain chain, SslPolicyErrors sslPolicyErrors) { return true; }
                    public static void Disable() { System.Net.ServicePointManager.ServerCertificateValidationCallback = ValidationCallback; }
                    public static void Enable()  { System.Net.ServicePointManager.ServerCertificateValidationCallback = null; }
                }"
        }
        [SslVerification]::Disable()
    }

    if ($APIPublisher) {
        $url += "/$APIPublisher"
    }

    if ($APIGroup) {
        $url += "/$APIGroup"
    }

    $url += "/$APIVersion"

    if ($companyId) {
        $url += "/companies($CompanyId)"
    }

    $url += "/$Query"

    if ($Query.Contains('?')) {
        $url += "&tenant=$tenant"
    }
    else {
        $url += "?tenant=$tenant"
    }

    $headers += @{"Content-Type" = "application/json" }
    
    if ($body) {
        $parameters += @{ "body" = $body | ConvertTo-Json }
    }

    Write-Host "Invoke $Method on $url"
    Invoke-RestMethod -Method $Method -uri "$url" -Headers $headers @parameters

    if ($sslverificationdisabled) {
        [SslVerification]::Enable()
    }

}
Set-Alias -Name Invoke-BCContainerApi -Value Invoke-NavContainerApi
Export-ModuleMember -Function Invoke-NavContainerApi -Alias Invoke-BCContainerApi
