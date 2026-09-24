function Get-JiraTicket {
    <#
    .SYNOPSIS
        Gets a Jira Cloud issue with its comments.
    .DESCRIPTION
        Gets the issue from /rest/api/3/issue/<key> and returns a summary object with the key, a
        browser URL, summary, status, assignee, reporter, dates, description and comments.

        Comments are returned as JiraComment objects. Comment bodies (Atlassian Document Format in
        API v3) are converted to plain text. The description is returned as Jira sends it.
    .PARAMETER IssueKey
        The issue key, for example PROJ-123.
    .EXAMPLE
        Get-JiraTicket -IssueKey 'PROJ-123'

        Gets issue PROJ-123.
    .EXAMPLE
        (Get-JiraTicket -IssueKey 'PROJ-123').Comments | Select-Object Author, Created, Body

        Lists the comments on an issue.
    .OUTPUTS
        PSCustomObject
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$IssueKey
    )

    Write-Verbose "Getting ticket details for issue key: $IssueKey"
    $ticket = Invoke-JiraRequest -Method Get -Resource 'issue' -Id $IssueKey

    if (-not $ticket) {
        Write-Warning "Failed to retrieve Jira ticket: $IssueKey. The response from the server was empty or invalid."
        return
    }

    Write-Verbose "Formatting ticket object for '$($ticket.key)'."
    $commentList = New-Object -TypeName 'System.Collections.Generic.List[JiraComment]'
    foreach ($comment in @($ticket.fields.comment.comments)) {
        if ($null -eq $comment) {
            continue
        }
        $jiraComment = New-Object -TypeName JiraComment
        $jiraComment.Id = $comment.id
        $jiraComment.Author = $comment.author.displayName
        $jiraComment.Body = ConvertFrom-JiraDocument -Document $comment.body
        if ($comment.created) { $jiraComment.Created = $comment.created }
        if ($comment.updated) { $jiraComment.Updated = $comment.updated }
        $jiraComment.UpdateAuthor = $comment.updateAuthor.displayName
        $commentList.Add($jiraComment)
    }
    Write-Verbose "Processed $($commentList.Count) comment(s)."

    [pscustomobject]@{
        Key         = $ticket.key
        Url         = "$($script:JiraContext.ConnectionURI)/browse/$($ticket.key)"
        Summary     = $ticket.fields.summary
        Status      = $ticket.fields.status.name
        Assignee    = $ticket.fields.assignee.displayName
        Reporter    = $ticket.fields.reporter.displayName
        Created     = $ticket.fields.created
        Updated     = $ticket.fields.updated
        Description = $ticket.fields.description
        Comments    = $commentList
    }
}
