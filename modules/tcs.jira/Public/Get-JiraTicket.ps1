# Gets the details of an existing Jira Cloud ticket.
function Get-JiraTicket {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$IssueKey
    )

    Write-Verbose "Getting ticket details for issue key: $IssueKey"
    $response = Invoke-JiraRequest -Method Get -Resource 'issue' -Id $IssueKey
    
    if ($response) {
        Write-Verbose "Response received from Invoke-JiraRequest."
        $ticket = $response
        
        Write-Verbose "Formatting ticket object for '$($ticket.key)'."
        $commentList = [System.Collections.Generic.List[JiraComment]]::new()
        if ($ticket.fields.comment.comments) {
            Write-Verbose "Found $($ticket.fields.comment.comments.Count) comments to process."
            foreach ($comment in $ticket.fields.comment.comments) {
                $commentList.Add([JiraComment]@{
                    Id           = $comment.id
                    Author       = $comment.author.displayName
                    Body         = $comment.body
                    Created      = $comment.created
                    Updated      = $comment.updated
                    UpdateAuthor = $comment.updateAuthor.displayName
                })
            }
        }

        $formattedTicket = [PSCustomObject]@{
            Key         = $ticket.key
            Url         = "$($JiraContext.ConnectionURI)/browse/$($ticket.key)"
            Summary     = $ticket.fields.summary
            Status      = $ticket.fields.status.name
            Assignee    = $ticket.fields.assignee.displayName
            Reporter    = $ticket.fields.reporter.displayName
            Created     = $ticket.fields.created
            Updated     = $ticket.fields.updated
            Description = $ticket.fields.description
            Comments    = $commentList
        }
        Write-Verbose "Successfully formatted ticket '$($ticket.key)'."
        return $formattedTicket
    } else {
        Write-Warning "Failed to retrieve Jira ticket: $IssueKey. The response from the server was empty or invalid."
        return $null
    }
}
