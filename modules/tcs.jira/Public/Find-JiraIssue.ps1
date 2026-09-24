function Find-JiraIssue {
    <#
    .SYNOPSIS
        Finds Jira Cloud issues with a JQL query.
    .DESCRIPTION
        Searches with the enhanced JQL search endpoint (GET /rest/api/3/search/jql), follows the
        nextPageToken pages and returns the issue objects as Jira sends them (id, key, self and
        fields) until -MaxResults issues have been returned or there are no more results.

        The output can be piped to Get-JiraTicket, Update-JiraTicket and Update-JSMRequest, which
        take the issue key from the 'key' property.
    .PARAMETER JQL
        The JQL query, for example 'project = PROJ AND statusCategory != Done'. Atlassian requires
        a bounded query (one with a search restriction).
    .PARAMETER Fields
        The fields to return for each issue, for example 'summary', 'status'. Defaults to
        '*navigable'. Use 'key' or 'id' alone for the fastest search.
    .PARAMETER MaxResults
        The maximum number of issues to return. Defaults to 100.
    .EXAMPLE
        Find-JiraIssue -JQL 'project = PROJ AND assignee = currentUser()' -Fields summary, status

        Returns your issues in PROJ with their summary and status.
    .EXAMPLE
        Find-JiraIssue -JQL 'project = PROJ AND labels = stale' -MaxResults 500 | Update-JiraTicket -Comment 'Closing stale issue' -MarkDone

        Comments on and closes up to 500 issues.
    .OUTPUTS
        PSCustomObject. The issue objects from the search response.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$JQL,

        [ValidateNotNullOrEmpty()]
        [string[]]$Fields = @('*navigable'),

        [ValidateRange(1, 100000)]
        [int]$MaxResults = 100
    )

    $TelemetryArgs = @{
        ModuleName    = $MyInvocation.MyCommand.Module.Name
        ModuleVersion = [string]$MyInvocation.MyCommand.Module.Version
        CommandName   = $MyInvocation.MyCommand.Name
        ExecutionID   = [guid]::NewGuid().ToString()
    }
    Invoke-TelemetryCollection @TelemetryArgs -Stage Start -ClearTimer
    try {
        $query = @{
            maxResults = [math]::Min($MaxResults, 100)
            fields     = ($Fields -join ',')
        }
        $returned = 0
        $more = $true
        while ($more -and $returned -lt $MaxResults) {
            $page = Invoke-JiraRequest -Method Get -URIPath '/search/jql' -JQL $JQL -Query $query -Raw
            foreach ($issue in @($page.issues)) {
                if ($null -eq $issue) { continue }
                if ($returned -ge $MaxResults) { break }
                $issue
                $returned++
            }
            $more = [bool]($page.nextPageToken) -and -not $page.isLast
            if ($more) {
                $query['nextPageToken'] = [string]$page.nextPageToken
            }
        }
        Write-Verbose "Returned $returned issue(s)."
        Invoke-TelemetryCollection @TelemetryArgs -Stage End
    }
    catch {
        Invoke-TelemetryCollection @TelemetryArgs -Stage End -Failed $true -Exception $_
        throw
    }
}
