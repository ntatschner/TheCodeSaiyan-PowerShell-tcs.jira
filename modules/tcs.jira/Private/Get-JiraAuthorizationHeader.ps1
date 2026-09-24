function Get-JiraAuthorizationHeader {
    <#
    .SYNOPSIS
        Builds the HTTP Basic Authorization header value from the stored Jira credential.
    .DESCRIPTION
        Jira Cloud expects 'Basic base64(email:api-token)', encoded as UTF-8. The value is built on
        demand for each request so that the token is never kept in a readable variable.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param ()

    if (-not $script:JiraCredential) {
        throw 'Jira context is not set. Run Set-JiraContext first.'
    }
    $pair = '{0}:{1}' -f $script:JiraCredential.UserName, $script:JiraCredential.GetNetworkCredential().Password
    'Basic ' + [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($pair))
}
