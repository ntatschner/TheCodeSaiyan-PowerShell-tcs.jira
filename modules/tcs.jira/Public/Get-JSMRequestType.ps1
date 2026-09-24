function Get-JSMRequestType {
    <#
    .SYNOPSIS
        Gets the request types of a Jira Service Management service desk.
    .DESCRIPTION
        Without -RequestTypeId, gets every request type of the service desk from
        GET /rest/servicedeskapi/servicedesk/<id>/requesttype, following all pages. With
        -RequestTypeId, gets that request type. Each request type has an id (use it with
        New-JSMRequest -RequestTypeId), a name, a description and the ids of its groups.
    .PARAMETER ServiceDeskId
        The id of the service desk, for example 1. Accepts pipeline input by property name
        (ServiceDeskId, or id from Get-JSMServiceDesk).
    .PARAMETER RequestTypeId
        The id of one request type.
    .PARAMETER MaxQueryPages
        The maximum number of pages to request when listing request types. Defaults to 10.
    .EXAMPLE
        Get-JSMRequestType -ServiceDeskId '1' | Select-Object id, name

        Lists the request types of service desk 1.
    .EXAMPLE
        Get-JSMServiceDesk | Where-Object projectKey -EQ 'SD' | Get-JSMRequestType

        Lists the request types of the SD service desk.
    .OUTPUTS
        PSCustomObject. The request type objects from Jira.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('id')]
        [ValidatePattern('^\d+$')]
        [string]$ServiceDeskId,

        [ValidatePattern('^\d+$')]
        [string]$RequestTypeId,

        [ValidateRange(1, 1000)]
        [int]$MaxQueryPages = 10
    )

    process {
        $TelemetryArgs = @{
            ModuleName    = $MyInvocation.MyCommand.Module.Name
            ModuleVersion = [string]$MyInvocation.MyCommand.Module.Version
            CommandName   = $MyInvocation.MyCommand.Name
            ExecutionID   = [guid]::NewGuid().ToString()
        }
        Invoke-TelemetryCollection @TelemetryArgs -Stage Start -ClearTimer
        try {
            $path = '/servicedeskapi/servicedesk/{0}/requesttype' -f [System.Uri]::EscapeDataString($ServiceDeskId)
            if ($RequestTypeId) {
                $path += '/' + [System.Uri]::EscapeDataString($RequestTypeId)
            }
            Invoke-JiraRequest -Method Get -URIPath $path -MaxQueryPages $MaxQueryPages
            Invoke-TelemetryCollection @TelemetryArgs -Stage End
        }
        catch {
            Invoke-TelemetryCollection @TelemetryArgs -Stage End -Failed $true -Exception $_
            throw
        }
    }
}
