function Get-JSMRequestTransition {
    <#
    .SYNOPSIS
        Gets the customer transitions of a Jira Service Management request.
    .DESCRIPTION
        Gets the transitions the calling account can perform on the request from
        GET /rest/servicedeskapi/request/<key>/transition, following all pages. Each transition
        has an id and a name; use the id with Set-JSMRequestTransition.
    .PARAMETER IssueKey
        The issue key or id of the request, for example SD-42. Accepts pipeline input by property
        name (IssueKey or Key).
    .EXAMPLE
        Get-JSMRequestTransition -IssueKey 'SD-42'

        Lists the transitions of request SD-42.
    .OUTPUTS
        PSCustomObject. The transition objects from Jira.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('Key')]
        [ValidatePattern('^([A-Za-z][A-Za-z0-9_]*-\d+|\d+)$')]
        [string]$IssueKey
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
            Invoke-JiraRequest -Method Get -URIPath "/servicedeskapi/request/$([System.Uri]::EscapeDataString($IssueKey))/transition"
            Invoke-TelemetryCollection @TelemetryArgs -Stage End
        }
        catch {
            Invoke-TelemetryCollection @TelemetryArgs -Stage End -Failed $true -Exception $_
            throw
        }
    }
}
