function Get-JSMRequest {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$IssueKey
    )
    if (-not $global:JiraContext) {
        throw "JiraContext is not set. Please run Set-JiraContext first."
    }
    $response = Invoke-JiraRequest -Method Get -URIPath "/servicedeskapi/request/$IssueKey"
    if ($response) {
        Write-Verbose "Successfully retrieved JSM request: $IssueKey."
        return $response
    } else {
        Write-Warning "Failed to retrieve JSM request: $IssueKey. The response from the server was empty or invalid."
        return $null
    }
}
