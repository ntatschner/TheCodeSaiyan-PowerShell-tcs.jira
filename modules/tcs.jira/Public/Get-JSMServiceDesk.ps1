function Get-JSMServiceDesk {
    <#
    .SYNOPSIS
        Gets Jira Service Management service desks.
    .DESCRIPTION
        Without -ServiceDeskId, gets every service desk the calling account can see from
        GET /rest/servicedeskapi/servicedesk, following all pages. With -ServiceDeskId, gets that
        service desk from GET /rest/servicedeskapi/servicedesk/<id>. Each service desk has an id
        (use it with New-JSMRequest and Get-JSMRequestType), projectId, projectName and projectKey.
    .PARAMETER ServiceDeskId
        The id of one service desk, for example 1.
    .PARAMETER MaxQueryPages
        The maximum number of pages to request when listing service desks. Defaults to 10.
    .EXAMPLE
        Get-JSMServiceDesk | Select-Object id, projectKey, projectName

        Lists the service desks.
    .OUTPUTS
        PSCustomObject. The service desk objects from Jira.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param (
        [ValidatePattern('^\d+$')]
        [string]$ServiceDeskId,

        [ValidateRange(1, 1000)]
        [int]$MaxQueryPages = 10
    )

    $TelemetryArgs = @{
        ModuleName    = $MyInvocation.MyCommand.Module.Name
        ModuleVersion = [string]$MyInvocation.MyCommand.Module.Version
        CommandName   = $MyInvocation.MyCommand.Name
        ExecutionID   = [guid]::NewGuid().ToString()
    }
    Invoke-TelemetryCollection @TelemetryArgs -Stage Start -ClearTimer
    try {
        $path = '/servicedeskapi/servicedesk'
        if ($ServiceDeskId) {
            $path += '/' + [System.Uri]::EscapeDataString($ServiceDeskId)
        }
        Invoke-JiraRequest -Method Get -URIPath $path -MaxQueryPages $MaxQueryPages
        Invoke-TelemetryCollection @TelemetryArgs -Stage End
    }
    catch {
        Invoke-TelemetryCollection @TelemetryArgs -Stage End -Failed $true -Exception $_
        throw
    }
}
