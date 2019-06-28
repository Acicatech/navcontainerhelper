﻿<# 
 .Synopsis
  Start a NAV/BC Container
 .Description
  Start a Container
 .Parameter containerName
  Name of the container you want to start
 .Parameter timeout
  Specify the number of seconds to wait for activity. Default is 1800 (30 min.), -1 means wait forever, 0 means don't wait.
 .Example
  Start-NavContainer -containerName test
#>
function Start-NavContainer {
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true, ValueFromPipeline)]
        [string] $containerName,
        [int] $timeout = 1800
    )

    if (!(DockerDo -command start -imageName $containerName)) {
        return
    }
    if ($timeout -ne 0) {
        Wait-NavContainerReady -containerName $containerName -timeout $timeout
    }
}
Set-Alias -Name Start-BCContainer -Value Start-NavContainer
Export-ModuleMember -Function Start-NavContainer -Alias Start-BCContainer
