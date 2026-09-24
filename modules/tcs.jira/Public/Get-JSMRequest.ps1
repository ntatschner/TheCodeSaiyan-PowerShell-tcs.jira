function Get-JSMRequest {
    <#
    .SYNOPSIS
        Gets a Jira Service Management customer request.
    .DESCRIPTION
        Gets the request from /rest/servicedeskapi/request/<key> and returns the response as Jira
        sends it.
    .PARAMETER IssueKey
        The issue key or id of the request, for example SD-42.
    .EXAMPLE
        Get-JSMRequest -IssueKey 'SD-42'

        Gets request SD-42.
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

    $response = Invoke-JiraRequest -Method Get -URIPath "/servicedeskapi/request/$IssueKey"
    if ($response) {
        Write-Verbose "Successfully retrieved JSM request: $IssueKey."
        return $response
    }
    Write-Warning "Failed to retrieve JSM request: $IssueKey. The response from the server was empty or invalid."
}
