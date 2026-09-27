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

    begin {
        $telemetry = Start-TcsTelemetry
        $lastError = $null
    }

    process {
        # finally also completes the run when a downstream command stops the pipeline or an
        # error bypasses catch; the end block does not run then
        $completed = $false
        try {
            Invoke-JiraRequest -Method Get -URIPath "/servicedeskapi/request/$([System.Uri]::EscapeDataString($IssueKey))/transition"
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
