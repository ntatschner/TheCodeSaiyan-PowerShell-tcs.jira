function Get-JiraTicket {
    <#
    .SYNOPSIS
        Gets a Jira Cloud issue with its comments.
    .DESCRIPTION
        Gets the issue from /rest/api/3/issue/<key> and returns a summary object with the key, a
        browser URL, summary, status, assignee, reporter, dates, description and comments.

        Created and Updated are [datetime] values. Description is returned as Jira sends it
        (an Atlassian Document Format object in API v3) and DescriptionText holds it as plain text.

        Comments are returned as objects with the type name tcs.jira.Comment and the properties
        Id, Author, Body, Created, Updated and UpdateAuthor. Comment bodies are converted to plain
        text and the dates are [datetime] values.

        Issue keys can be piped in, for example from Find-JiraIssue (any object with an IssueKey
        or Key property).
    .PARAMETER IssueKey
        The issue key or id, for example PROJ-123. Accepts pipeline input by property name
        (IssueKey or Key).
    .EXAMPLE
        Get-JiraTicket -IssueKey 'PROJ-123'

        Gets issue PROJ-123.
    .EXAMPLE
        (Get-JiraTicket -IssueKey 'PROJ-123').Comments | Select-Object Author, Created, Body

        Lists the comments on an issue.
    .EXAMPLE
        Find-JiraIssue -JQL 'project = PROJ AND updated >= -1d' | Get-JiraTicket

        Gets every issue updated in the last day, with comments.
    .OUTPUTS
        PSCustomObject
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
            Write-Verbose "Getting ticket details for issue key: $IssueKey"
            $ticket = Invoke-JiraRequest -Method Get -Resource 'issue' -Id $IssueKey

            if (-not $ticket) {
                Write-Warning "Failed to retrieve Jira ticket: $IssueKey. The response from the server was empty or invalid."
                Invoke-TelemetryCollection @TelemetryArgs -Stage End
                return
            }

            Write-Verbose "Formatting ticket object for '$($ticket.key)'."
            $commentList = New-Object -TypeName 'System.Collections.Generic.List[object]'
            foreach ($comment in @($ticket.fields.comment.comments)) {
                if ($null -eq $comment) {
                    continue
                }
                $commentList.Add([pscustomobject]@{
                        PSTypeName   = 'tcs.jira.Comment'
                        Id           = [string]$comment.id
                        Author       = [string]$comment.author.displayName
                        Body         = ConvertFrom-JiraDocument -Document $comment.body
                        Created      = ConvertTo-JiraDateTime -Value $comment.created
                        Updated      = ConvertTo-JiraDateTime -Value $comment.updated
                        UpdateAuthor = [string]$comment.updateAuthor.displayName
                    })
            }
            Write-Verbose "Processed $($commentList.Count) comment(s)."

            [pscustomobject]@{
                Key             = $ticket.key
                Url             = "$($script:JiraContext.ConnectionURI)/browse/$($ticket.key)"
                Summary         = $ticket.fields.summary
                Status          = $ticket.fields.status.name
                Assignee        = $ticket.fields.assignee.displayName
                Reporter        = $ticket.fields.reporter.displayName
                Created         = ConvertTo-JiraDateTime -Value $ticket.fields.created
                Updated         = ConvertTo-JiraDateTime -Value $ticket.fields.updated
                Description     = $ticket.fields.description
                DescriptionText = ConvertFrom-JiraDocument -Document $ticket.fields.description
                Comments        = $commentList.ToArray()
            }
            Invoke-TelemetryCollection @TelemetryArgs -Stage End
        }
        catch {
            Invoke-TelemetryCollection @TelemetryArgs -Stage End -Failed $true -Exception $_
            throw
        }
    }
}
