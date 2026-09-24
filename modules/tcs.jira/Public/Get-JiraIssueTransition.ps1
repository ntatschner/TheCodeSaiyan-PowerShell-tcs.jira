function Get-JiraIssueTransition {
    <#
    .SYNOPSIS
        Gets the transitions that can be performed on a Jira Cloud issue.
    .DESCRIPTION
        Gets the transitions from GET /rest/api/3/issue/<key>/transitions for the issue's current
        status and the calling account. Each transition has an id, a name and a 'to' object with
        the target status (to.name).
    .PARAMETER IssueKey
        The issue key or id, for example PROJ-123. Accepts pipeline input by property name
        (IssueKey or Key).
    .EXAMPLE
        Get-JiraIssueTransition -IssueKey 'PROJ-123' | Select-Object id, name, @{ n = 'To'; e = { $_.to.name } }

        Lists the transitions and their target statuses.
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
            $response = Invoke-JiraRequest -Method Get -URIPath "/issue/$([System.Uri]::EscapeDataString($IssueKey))/transitions"
            foreach ($transition in @($response.transitions)) {
                if ($null -ne $transition) {
                    $transition
                }
            }
            Invoke-TelemetryCollection @TelemetryArgs -Stage End
        }
        catch {
            Invoke-TelemetryCollection @TelemetryArgs -Stage End -Failed $true -Exception $_
            throw
        }
    }
}
