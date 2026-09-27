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

    begin {
        $telemetry = Start-TcsTelemetry
        $lastError = $null
    }

    process {
        # finally also completes the run when a downstream command stops the pipeline or an
        # error bypasses catch; the end block does not run then
        $completed = $false
        try {
            $response = Invoke-JiraRequest -Method Get -URIPath "/issue/$([System.Uri]::EscapeDataString($IssueKey))/transitions"
            foreach ($transition in @($response.transitions)) {
                if ($null -ne $transition) {
                    $transition
                }
            }
            $completed = $true
        }
        catch {
            $lastError = $_
            throw
        }
        finally {
            if (-not $completed) {
                Complete-TcsTelemetry -Token $telemetry -ErrorRecord $lastError
            }
        }
    }

    end {
        Complete-TcsTelemetry -Token $telemetry -ErrorRecord $lastError
    }
}
