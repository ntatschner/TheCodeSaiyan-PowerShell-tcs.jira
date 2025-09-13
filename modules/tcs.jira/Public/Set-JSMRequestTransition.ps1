function Set-JSMRequestTransition {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$IssueKey,
        [Parameter(Mandatory = $true)]
        [string]$TransitionId
    )
    if (-not $global:JiraContext) {
        throw "JiraContext is not set. Please run Set-JiraContext first."
    }
    $body = @{ transition = @{ id = $TransitionId } } | ConvertTo-Json
    $result = Invoke-JiraRequest -Method Post -URIPath "/servicedeskapi/request/$IssueKey/transition" -Body $body
    if ($result) {
        Write-Host "Successfully transitioned JSM request $IssueKey."
        return $result
    }
    return $null
}
