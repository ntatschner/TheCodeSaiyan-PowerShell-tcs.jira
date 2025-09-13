function New-JSMRequest {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ServiceDeskId,
        [Parameter(Mandatory = $true)]
        [string]$RequestTypeId,
        [Parameter(Mandatory = $true)]
        [string]$Summary,
        [string]$Description,
        [Parameter(Mandatory = $true)]
        [string]$Reporter
    )

    if (-not $global:JiraContext) {
        throw "JiraContext is not set. Please run Set-JiraContext first."
    }

    $body = @{
        serviceDeskId   = $ServiceDeskId
        requestTypeId   = $RequestTypeId
        requestFieldValues = @{
            summary     = $Summary
            description = $Description
        }
        reporter = $Reporter
    } | ConvertTo-Json -Depth 5

    $result = Invoke-JiraRequest -Method Post -URIPath "/servicedeskapi/request" -Body $body
    if ($result) {
        Write-Host "Successfully created JSM request: $($result.issueKey)"
        return $result
    }
    return $null
}
