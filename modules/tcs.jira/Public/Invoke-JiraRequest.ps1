function Invoke-JiraRequest {
    <#
    .SYNOPSIS
        Sends a request to the Jira Cloud or Jira Service Management REST API.
    .DESCRIPTION
        Builds the request URL from the context set by Set-JiraContext, adds the Authorization
        header, sends the request and returns the parsed response.

        Path handling:
        - Paths starting with /rest/ are used as they are (for example /rest/agile/1.0/board).
        - Paths starting with /servicedeskapi/ are sent to /rest/servicedeskapi/...
        - Any other path is sent to the Jira platform API, /rest/api/3/...

        Search results (objects with an 'issues' property) are unwrapped to the issues. Pages are
        followed through 'nextPageToken' (JQL search) or a 'nextPage' URL on the same site, up to
        -MaxQueryPages. Requests that fail with HTTP 429 or 503 are retried up to three times.
        Errors are terminating and include the HTTP status and Jira's error details, never the
        credentials.
    .PARAMETER Method
        The HTTP method: Get, Post, Put, Delete or Patch.
    .PARAMETER URIPath
        The API path, for example /issue/JRA-9 or /servicedeskapi/request/SD-1. Takes precedence
        over -Resource and -JQL.
    .PARAMETER Resource
        A Jira platform resource shortcut (issue, project, search, user or group), combined with -Id.
    .PARAMETER Id
        The identifier appended to -Resource, for example an issue key.
    .PARAMETER Body
        The JSON request body. It is sent as UTF-8.
    .PARAMETER Query
        Query string parameters. Keys and values are URL-encoded. The hashtable is not modified.
    .PARAMETER JQL
        A JQL query. Without -URIPath the request goes to the enhanced search endpoint
        /rest/api/3/search/jql and returns all navigable fields unless -Query sets 'fields'.
    .PARAMETER MaxQueryPages
        The maximum number of pages to request. Defaults to 10.
    .EXAMPLE
        Invoke-JiraRequest -Method Get -Resource issue -Id 'PROJ-123'

        Gets an issue.
    .EXAMPLE
        Invoke-JiraRequest -Method Get -JQL 'project = PROJ AND status = "In Progress"' -Query @{ maxResults = 100 }

        Returns the issues that match a JQL query.
    .EXAMPLE
        Invoke-JiraRequest -Method Get -URIPath '/servicedeskapi/request/SD-42'

        Gets a Jira Service Management request.
    .OUTPUTS
        The parsed response objects.
    #>
    [CmdletBinding()]
    [OutputType([object])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Get', 'Post', 'Put', 'Delete', 'Patch')]
        [string]$Method,

        [Parameter(HelpMessage = 'Explicit URI path (e.g., /issue/JRA-9). Takes precedence over -Resource.')]
        [string]$URIPath,

        [Parameter(HelpMessage = 'High-level resource shortcut.')]
        [ValidateSet('issue', 'project', 'search', 'user', 'group')]
        [string]$Resource,

        [string]$Id,

        [string]$Body,

        [hashtable]$Query,

        [string]$JQL,

        [ValidateRange(1, 1000)]
        [int]$MaxQueryPages = 10
    )

    $TelemetryArgs = @{
        ModuleName    = $MyInvocation.MyCommand.Module.Name
        ModuleVersion = [string]$MyInvocation.MyCommand.Module.Version
        CommandName   = $MyInvocation.MyCommand.Name
        ExecutionID   = [guid]::NewGuid().ToString()
    }
    Invoke-TelemetryCollection @TelemetryArgs -Stage Start -ClearTimer
    try {
        if (-not $script:JiraContext -or -not $script:JiraCredential) {
            throw 'Jira context is not set. Run Set-JiraContext first.'
        }
        $baseUri = ([string]$script:JiraContext.ConnectionURI).TrimEnd('/')

        # --- Request path ---
        if ($URIPath) {
            $requestPath = $URIPath
        }
        elseif ($JQL) {
            $requestPath = '/search/jql'
        }
        elseif ($Resource) {
            $requestPath = "/$Resource"
            if ($Id) {
                $requestPath += "/$Id"
            }
            Write-Verbose "Constructed request path from -Resource: $requestPath"
        }
        else {
            throw 'Either -URIPath, -Resource or -JQL must be specified.'
        }
        if (-not $requestPath.StartsWith('/')) {
            $requestPath = "/$requestPath"
        }

        if ($requestPath -like '/rest/*') {
            $apiPath = $requestPath
        }
        elseif ($requestPath -like '/servicedeskapi/*') {
            $apiPath = "/rest$requestPath"
        }
        else {
            $apiPath = "/rest/api/3$requestPath"
        }
        $endpointBase = "$baseUri$apiPath"
        Write-Verbose "Endpoint base (pre-query): $endpointBase"

        # --- Query parameters (copied so the caller's hashtable is not changed) ---
        $queryParameters = [ordered]@{}
        if ($Query) {
            foreach ($key in $Query.Keys) {
                $queryParameters[[string]$key] = $Query[$key]
            }
        }
        if ($JQL) {
            $queryParameters['jql'] = $JQL
            if ($apiPath -like '*/search/jql' -and -not $queryParameters.Contains('fields')) {
                # The enhanced search endpoint only returns issue ids unless fields are requested
                $queryParameters['fields'] = '*navigable'
            }
        }

        $headers = @{
            Authorization = Get-JiraAuthorizationHeader
            Accept        = 'application/json'
        }

        $allResults = New-Object -TypeName 'System.Collections.Generic.List[object]'
        $nextUri = $null
        $pageCount = 0
        $maxAttempts = 3
        $retryDelaySeconds = 2

        do {
            if ($nextUri) {
                $uri = $nextUri
            }
            else {
                $pairs = @(foreach ($key in $queryParameters.Keys) {
                        '{0}={1}' -f [System.Uri]::EscapeDataString([string]$key), [System.Uri]::EscapeDataString([string]$queryParameters[$key])
                    })
                $uri = $endpointBase
                if ($pairs.Count -gt 0) {
                    $uri = '{0}?{1}' -f $endpointBase, ($pairs -join '&')
                }
            }

            $requestParameters = @{
                Uri         = $uri
                Method      = $Method
                Headers     = $headers
                ContentType = 'application/json; charset=utf-8'
                ErrorAction = 'Stop'
            }
            if ($PSBoundParameters.ContainsKey('Body')) {
                $requestParameters['Body'] = $Body
            }
            Write-Verbose ('[Page {0}] {1} {2}' -f ($pageCount + 1), $Method.ToUpperInvariant(), $uri)

            $attempt = 0
            $response = $null
            while ($true) {
                $attempt++
                try {
                    $response = Invoke-RestMethod @requestParameters
                    break
                }
                catch {
                    $caught = $_
                    $statusCode = $null
                    if ($caught.Exception.Response -and $caught.Exception.Response.StatusCode) {
                        $statusCode = [int]$caught.Exception.Response.StatusCode
                    }
                    elseif ($caught.ErrorDetails -and $caught.ErrorDetails.Message -match '"status"\s*:\s*(\d+)') {
                        $statusCode = [int]$Matches[1]
                    }

                    if (($statusCode -eq 429 -or $statusCode -eq 503) -and $attempt -lt $maxAttempts) {
                        Write-Warning "Jira returned HTTP $statusCode. Retrying in $retryDelaySeconds seconds (attempt $attempt of $maxAttempts)."
                        Start-Sleep -Seconds $retryDelaySeconds
                        continue
                    }

                    $errorMessage = "Jira request $($Method.ToUpperInvariant()) '$uri' failed."
                    if ($statusCode) {
                        $errorMessage += " HTTP status code: $statusCode."
                    }
                    if ($caught.ErrorDetails -and $caught.ErrorDetails.Message) {
                        $errorMessage += " Details: $($caught.ErrorDetails.Message)"
                    }
                    elseif ($caught.Exception.Response -is [System.Net.WebResponse]) {
                        # Windows PowerShell: read the error body from the response stream
                        try {
                            $reader = New-Object -TypeName System.IO.StreamReader -ArgumentList $caught.Exception.Response.GetResponseStream()
                            $errorMessage += " Details: $($reader.ReadToEnd())"
                            $reader.Close()
                        }
                        catch {
                            $errorMessage += " Details: $($_.Exception.Message)"
                        }
                    }
                    else {
                        $errorMessage += " Details: $($caught.Exception.Message)"
                    }

                    $exception = New-Object -TypeName System.InvalidOperationException -ArgumentList $errorMessage, $caught.Exception
                    $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $exception, 'JiraRequestFailed', ([System.Management.Automation.ErrorCategory]::InvalidResult), $uri
                    $PSCmdlet.ThrowTerminatingError($errorRecord)
                }
            }

            # --- Collect results ---
            $nextUri = $null
            $morePages = $false
            if ($response -is [array]) {
                foreach ($item in $response) {
                    $allResults.Add($item)
                }
            }
            elseif ($null -ne $response -and -not ($response -is [string] -and $response.Length -eq 0)) {
                $propertyNames = @($response.PSObject.Properties.Name)
                if ($propertyNames -contains 'issues') {
                    Write-Verbose 'Detected a search result object. Extracting issues.'
                    foreach ($item in @($response.issues)) {
                        if ($null -ne $item) {
                            $allResults.Add($item)
                        }
                    }
                }
                else {
                    $allResults.Add($response)
                }

                if ($propertyNames -contains 'nextPageToken' -and $response.nextPageToken -and -not ($propertyNames -contains 'isLast' -and $response.isLast)) {
                    $queryParameters['nextPageToken'] = [string]$response.nextPageToken
                    $morePages = $true
                }
                elseif ($propertyNames -contains 'nextPage' -and $response.nextPage) {
                    $candidate = [string]$response.nextPage
                    if ($candidate.StartsWith("$baseUri/", [System.StringComparison]::OrdinalIgnoreCase)) {
                        $nextUri = $candidate
                        $morePages = $true
                    }
                    else {
                        Write-Warning "Not following a pagination link outside '$baseUri'."
                    }
                }
            }
            $pageCount++
        } while ($morePages -and $pageCount -lt $MaxQueryPages)

        if ($morePages) {
            Write-Warning "Stopped after $MaxQueryPages page(s); more results are available. Increase -MaxQueryPages to get them."
        }

        Write-Verbose "Response received. Total result objects collected: $($allResults.Count)"
        $allResults
        Invoke-TelemetryCollection @TelemetryArgs -Stage End
    }
    catch {
        Invoke-TelemetryCollection @TelemetryArgs -Stage End -Failed $true -Exception $_
        throw
    }
}
