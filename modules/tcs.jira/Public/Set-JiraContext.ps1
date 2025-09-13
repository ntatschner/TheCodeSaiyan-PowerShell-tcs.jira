function Set-JiraContext {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The base URL of the Jira instance.")]
        [ValidatePattern('^https://')]
        [string]$JiraUrl,
        [Parameter(Mandatory)][Alias("EmailAddress")][string]$Username,
        [Parameter(Mandatory)][Alias("PAT")][string]$PersonalAccessToken
    )

    # --- Normalize base URL ---
    $raw = $JiraUrl.Trim().TrimEnd('/')
    $normalized = ($raw -replace '(?i)/rest/api/(\d|v\d)+/?$', '')
    $ConnectionURI = $normalized

    $basicPair  = "${Username}:${PersonalAccessToken}"
    $authHeader = "Basic " + [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($basicPair))

    $ContextParams = @{
        OriginalConnectionURL = $raw
        ConnectionURI         = $ConnectionURI
        Username              = $Username
        PersonalAccessToken   = ('*' * 8)
        AuthorizationHeader   = @{
            Authorization = $authHeader
            ContentType   = "application/json"
            Accept        = "application/json"
        }
    }
    $global:JiraContext = [pscustomobject]$ContextParams
    Write-Verbose "Jira context set. Base='$normalized'"
}
