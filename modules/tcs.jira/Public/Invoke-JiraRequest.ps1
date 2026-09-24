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

        Responses are unwrapped and paged, up to -MaxQueryPages pages:
        - JQL search results (/rest/api/3/search/jql) are unwrapped to their issues and pages are
          followed through 'nextPageToken'. Other responses with an 'issues' property (for example
          the bulk create response, which also has 'errors') are returned unchanged.
        - Jira platform pages ('values' with 'isLast', 'nextPage', 'startAt' or 'maxResults') are
          unwrapped to their values and the 'nextPage' URL is followed.
        - Jira Service Management pages ('values' with 'isLastPage') are unwrapped to their values
          and the '_links.next' URL is followed.
        Pagination links are only followed when they point to the site set by Set-JiraContext.
        Use -Raw to get the response exactly as Jira sends it, without unwrapping or paging.

        Retries: HTTP 429 is retried for every method. Other 5xx errors are retried only for the
        idempotent methods Get, Put and Delete, so a Post (for example creating an issue) is never
        sent twice. At most three attempts are made; the wait honours the Retry-After header
        (capped at 60 seconds) and is otherwise 2, then 4 seconds.

        Errors are terminating and include the HTTP status and Jira's error details, never the
        credentials.
    .PARAMETER Method
        The HTTP method: Get, Post, Put, Delete or Patch.
    .PARAMETER URIPath
        The API path, for example /issue/JRA-9 or /servicedeskapi/request/SD-1. Takes precedence
        over -Resource and -JQL.
    .PARAMETER Resource
        A Jira platform resource shortcut (issue, project, search, user or group), combined with -Id.
        'search' is sent to the enhanced JQL search endpoint /rest/api/3/search/jql and does not
        take -Id.
    .PARAMETER Id
        The identifier appended to -Resource, for example an issue key. It is URL-encoded as one
        path segment, so it cannot add further path segments or a query string; use -URIPath for
        sub-resources such as /issue/PROJ-1/transitions.
    .PARAMETER Body
        The request body. A string is sent as it is (it should be JSON). Any other object, such
        as a hashtable, is converted to JSON (depth 20).
    .PARAMETER Query
        Query string parameters. Keys and values are URL-encoded. The hashtable is not modified.
    .PARAMETER JQL
        A JQL query. Without -URIPath the request goes to the enhanced search endpoint
        /rest/api/3/search/jql and returns all navigable fields unless -Query sets 'fields'.
    .PARAMETER MaxQueryPages
        The maximum number of pages to request. Defaults to 10.
    .PARAMETER Raw
        Returns the response exactly as Jira sends it: search results and pages are not unwrapped
        and only one request is made.
    .EXAMPLE
        Invoke-JiraRequest -Method Get -Resource issue -Id 'PROJ-123'

        Gets an issue.
    .EXAMPLE
        Invoke-JiraRequest -Method Get -JQL 'project = PROJ AND status = "In Progress"' -Query @{ maxResults = 100 }

        Returns the issues that match a JQL query.
    .EXAMPLE
        Invoke-JiraRequest -Method Get -URIPath '/servicedeskapi/request/SD-42'

        Gets a Jira Service Management request.
    .EXAMPLE
        Invoke-JiraRequest -Method Post -URIPath '/issue/bulk' -Body @{ issueUpdates = $updates } -Raw

        Creates issues in bulk and returns the whole response, including its 'errors'.
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

        [object]$Body,

        [hashtable]$Query,

        [string]$JQL,

        [ValidateRange(1, 1000)]
        [int]$MaxQueryPages = 10,

        [switch]$Raw
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
        elseif ($Resource -eq 'search') {
            # /rest/api/3/search was retired by Atlassian; the enhanced search uses nextPageToken paging
            if ($Id) {
                throw '-Id cannot be used with -Resource search. Use -JQL or -Query to search.'
            }
            $requestPath = '/search/jql'
        }
        elseif ($Resource) {
            $requestPath = "/$Resource"
            if ($Id) {
                # One encoded path segment: '/', '?', '#' and '..' cannot change the request
                $requestPath += '/' + [System.Uri]::EscapeDataString($Id)
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
        # Only JQL search results are unwrapped to their issues (not bulk create responses)
        $isSearch = ($apiPath -split '\?')[0] -match '(?i)^/rest/api/(2|3|latest)/search(/jql)?/?$'
        $requestBody = $null
        if ($PSBoundParameters.ContainsKey('Body')) {
            if ($null -eq $Body -or $Body -is [string]) {
                $requestBody = $Body
            }
            else {
                $requestBody = ConvertTo-Json -InputObject $Body -Depth 20
            }
        }
        $isIdempotent = $Method -in @('Get', 'Put', 'Delete')
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
                $requestParameters['Body'] = $requestBody
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

                    # 429: the request was not processed, so any method can be retried.
                    # 5xx: only idempotent methods, a POST may already have created something.
                    $retryable = ($statusCode -eq 429) -or ($isIdempotent -and $statusCode -ge 500 -and $statusCode -le 599)
                    if ($retryable -and $attempt -lt $maxAttempts) {
                        $retryDelaySeconds = Get-JiraRetryDelay -Response $caught.Exception.Response -Attempt $attempt
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
            if ($Raw) {
                if ($null -ne $response) {
                    # -Raw: one request, the response exactly as received
                    , $response
                }
                break
            }
            if ($response -is [array]) {
                foreach ($item in $response) {
                    $allResults.Add($item)
                }
            }
            elseif ($null -ne $response -and -not ($response -is [string] -and $response.Length -eq 0)) {
                $propertyNames = @($response.PSObject.Properties.Name)
                $isPlatformPage = ($propertyNames -contains 'values') -and (
                    ($propertyNames -contains 'isLast') -or ($propertyNames -contains 'nextPage') -or
                    ($propertyNames -contains 'startAt') -or ($propertyNames -contains 'maxResults'))
                $isServiceDeskPage = ($propertyNames -contains 'values') -and ($propertyNames -contains 'isLastPage')
                $pageLink = $null

                if ($isSearch -and $propertyNames -contains 'issues') {
                    Write-Verbose 'Detected a search result object. Extracting issues.'
                    foreach ($item in @($response.issues)) {
                        if ($null -ne $item) {
                            $allResults.Add($item)
                        }
                    }
                    # nextPageToken is a query parameter only for GET; POST search takes it in the body
                    if ($Method -eq 'Get' -and $propertyNames -contains 'nextPageToken' -and $response.nextPageToken -and -not ($propertyNames -contains 'isLast' -and $response.isLast)) {
                        $queryParameters['nextPageToken'] = [string]$response.nextPageToken
                        $morePages = $true
                    }
                }
                elseif ($isServiceDeskPage) {
                    Write-Verbose 'Detected a Service Management page. Extracting values.'
                    foreach ($item in @($response.values)) {
                        if ($null -ne $item) {
                            $allResults.Add($item)
                        }
                    }
                    if (-not $response.isLastPage -and $response._links -and $response._links.next) {
                        $pageLink = [string]$response._links.next
                    }
                }
                elseif ($isPlatformPage) {
                    Write-Verbose 'Detected a page of values. Extracting values.'
                    foreach ($item in @($response.values)) {
                        if ($null -ne $item) {
                            $allResults.Add($item)
                        }
                    }
                    if (-not ($propertyNames -contains 'isLast' -and $response.isLast) -and $propertyNames -contains 'nextPage' -and $response.nextPage) {
                        $pageLink = [string]$response.nextPage
                    }
                }
                else {
                    $allResults.Add($response)
                }

                if ($pageLink) {
                    if ($pageLink.StartsWith("$baseUri/", [System.StringComparison]::OrdinalIgnoreCase)) {
                        $nextUri = $pageLink
                        $morePages = $true
                    }
                    else {
                        Write-Warning "Not following a pagination link outside '$baseUri'."
                    }
                }
            }
            $pageCount++
        } while ($morePages -and $pageCount -lt $MaxQueryPages)

        if ($Raw) {
            Invoke-TelemetryCollection @TelemetryArgs -Stage End
            return
        }
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
