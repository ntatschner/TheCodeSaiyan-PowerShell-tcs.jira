function Add-JiraIssueComment {
    <#
    .SYNOPSIS
        Adds a plain-text comment to a Jira issue or Service Management request.
    .DESCRIPTION
        Without -ServiceManagement the comment is sent to POST /rest/api/3/issue/<key>/comment as an
        Atlassian Document Format paragraph. With -ServiceManagement it is sent to
        POST /rest/servicedeskapi/request/<key>/comment with 'public' set from -Public (a public
        comment is visible to the customer, an internal one only to agents).

        A failure is rethrown as the original error record from Invoke-JiraRequest.
    #>
    [CmdletBinding()]
    [OutputType([object])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$IssueKey,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Text,

        [switch]$ServiceManagement,

        [bool]$Public = $true
    )

    $escapedKey = [System.Uri]::EscapeDataString($IssueKey)
    if ($ServiceManagement) {
        $path = "/servicedeskapi/request/$escapedKey/comment"
        $body = @{ body = $Text; public = $Public }
    }
    else {
        $path = "/issue/$escapedKey/comment"
        $body = @{ body = (ConvertTo-JiraDocument -Text $Text) }
    }
    # Errors are terminating ErrorRecords (JiraRequestFailed) and reach the caller unchanged
    $result = Invoke-JiraRequest -Method Post -URIPath $path -Body $body -ErrorAction Stop
    Write-Verbose "Comment added to $IssueKey."
    $result
}
