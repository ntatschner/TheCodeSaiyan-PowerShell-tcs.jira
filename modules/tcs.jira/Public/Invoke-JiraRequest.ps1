function Invoke-JiraRequest {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Method,

        [Parameter(HelpMessage = "Explicit URI path (e.g., /issue/JRA-9). Takes precedence over -Resource.")]
        [string]$URIPath,

        [Parameter(HelpMessage = "High-level resource shortcut.")]
        [ValidateSet('issue', 'project', 'search', 'user', 'group')]
        [string]$Resource,

        [string]$Id,

        [string]$Body,

        [hashtable]$Query,

        [string]$JQL,

        [int16]$MaxQueryPages = 10
    )

    begin {
        # Helper for URL encoding
        function _Encode([string]$v) {
            if ($null -eq $v) { return "" }
            return [System.Net.WebUtility]::UrlEncode($v)
        }

        if (-not (Get-Variable -Scope Global -Name "JiraContext" -ErrorAction SilentlyContinue)) {
            throw "JiraContext variable not found. Please run Set-JiraContext to set the token."
        }

        # Normalize the base URI from context
        $rawBase = ($JiraContext.ConnectionURI | ForEach-Object { "$($_)" }) -join ''
        $rawBase = $rawBase.Trim().Trim('"').Trim("'")
        $rawBase = ($rawBase -replace '\s+', '') -replace '^(https?://)+', '$1'
        if ($rawBase -notmatch '^[a-zA-Z][a-zA-Z0-9+\-.]*://') {
            $rawBase = "https://$rawBase"
        }
        $rawBase = $rawBase.TrimEnd('/')

        # Determine request path
        $requestPath = $URIPath
        if ($JQL) {
            $Resource = 'search'
        }

        if (-not $URIPath) {
            if (-not $Resource) {
                throw "Either -URIPath or -Resource must be specified."
            }
            $requestPath = "/$Resource"
            if ($Id) {
                $requestPath += "/$Id"
            }
            Write-Verbose "Constructed request path from -Resource: $requestPath"
        }


        # Determine correct API base path
        if ($requestPath -like "/servicedeskapi/*") {
            $apiBasePath = ""
        } else {
            $apiBasePath = "/rest/api/3"
        }
        if ($JQL) {
            if (-not $Query) { $Query = @{} }
            $Query['jql'] = $JQL
        }

        $EndpointBase = "$rawBase$apiBasePath$requestPath"
        Write-Verbose "Endpoint base (pre-query): $EndpointBase"

        # Build query string
        $QueryParts = @()
        if ($Query) {
            foreach ($k in $Query.Keys) {
                $QueryParts += ("{0}={1}" -f (_Encode $k), (_Encode ([string]$Query[$k])))
            }
        }

        $script:__IJR_Endpoint = $EndpointBase
        if ($QueryParts.Count -gt 0) {
            $queryString = ($QueryParts -join '&')
            $script:__IJR_Endpoint = "$EndpointBase`?$queryString"
        }
        
        Write-Verbose "Full request URI: $($script:__IJR_Endpoint)"
    }
    process {
        $AllResults = @()
        $CurrentEndpoint = $script:__IJR_Endpoint
        $QueryPageCount = 0
        
        do {
            $WRSplat = @{
                Uri         = $CurrentEndpoint
                Headers     = $JiraContext.AuthorizationHeader
                Method      = $Method
                ContentType = "application/json"
            }
            if ($Body) { $WRSplat.Body = $Body }
            Write-Verbose ("[Page {0}] {1} {2}" -f ($QueryPageCount + 1), $Method.ToUpper(), $CurrentEndpoint)
            
            $maxRetries = 3
            $retryDelay = 2
            $attempt = 0
            while ($true) {
                try {
                    $Response = Invoke-RestMethod @WRSplat -ErrorAction Stop
                    # If the response is a search result, extract the 'issues'
                    if ($Response.PSObject.Properties.Name -contains 'issues') {
                        Write-Verbose "Detected a search result object. Extracting issues."
                        $AllResults += $Response.issues
                    } else {
                        $AllResults += $Response
                    }
                    # Handle pagination for paginated GET requests
                    if ($Response.PSObject.Properties.Name -contains 'nextPage' -and $Response.nextPage) {
                        $CurrentEndpoint = $Response.nextPage
                    } else {
                        $CurrentEndpoint = $null
                    }
                    break
                } catch {
                    $attempt++
                    $ErrorMessage = "Jira request to '$($WRSplat.Uri)' failed."
                    $statusCode = $null
                    if ($_.Exception.Response -and $_.Exception.Response.StatusCode) {
                        $statusCode = [int]$_.Exception.Response.StatusCode
                    } elseif ($_.ErrorDetails -and $_.ErrorDetails.Message -match '"status":\s*(\d+)') {
                        $statusCode = [int]($matches[1])
                    }
                    if ($statusCode) {
                        $ErrorMessage += " HTTP Status Code: $statusCode."
                    }
                    if ($statusCode -eq 503 -and $attempt -lt $maxRetries) {
                        Write-Warning "Received 503 Service Unavailable. Retrying in $retryDelay seconds... (Attempt $attempt/$maxRetries)"
                        Start-Sleep -Seconds $retryDelay
                        continue
                    }
                    if ($_.ErrorDetails -and $_.ErrorDetails.Message) {
                        $ErrorMessage += " Details: $($_.ErrorDetails.Message)"
                    } elseif ($_.Exception.Response -is [System.Net.WebResponse]) {
                        # Windows PowerShell
                        $resp = $_.Exception.Response
                        $ErrorContent = $resp.GetResponseStream()
                        $StreamReader = New-Object System.IO.StreamReader($ErrorContent)
                        $JiraError = $StreamReader.ReadToEnd()
                        $StreamReader.Close()
                        $ErrorMessage += " Details: $JiraError"
                    } else {
                        $ErrorMessage += " Details: $($_.Exception.Message)"
                    }
                    throw $ErrorMessage
                }
            }
        } while ($CurrentEndpoint -and (++$QueryPageCount -lt $MaxQueryPages))

        Write-Verbose "Response received. Total result objects collected: $($AllResults.Count)"
        return $AllResults
    }
}
