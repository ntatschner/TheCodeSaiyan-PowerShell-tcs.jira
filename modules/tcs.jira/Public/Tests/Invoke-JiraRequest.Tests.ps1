BeforeAll {
    $env:TCS_CONFIG_ROOT = Join-Path -Path $TestDrive -ChildPath 'config'
    $env:TCS_SKIP_UPDATE_CHECK = '1'
    $env:TCS_TELEMETRY_OPTOUT = '1'
    $ModuleRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
    Import-Module -Name (Join-Path -Path $ModuleRoot -ChildPath 'tcs.jira.psd1') -Force

    $Token = 'tok-SECRET-123'
    $EncodedPair = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes("user@contoso.com:$Token"))
    $Base = 'https://contoso.atlassian.net'

    function New-HttpError {
        param ([int]$StatusCode, [string]$Details, [hashtable]$Headers = @{})
        $exception = New-Object -TypeName System.Exception -ArgumentList "Response status code does not indicate success: $StatusCode"
        $exception | Add-Member -NotePropertyName Response -NotePropertyValue ([pscustomobject]@{ StatusCode = $StatusCode; Headers = $Headers })
        $record = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $exception, 'HttpError', ([System.Management.Automation.ErrorCategory]::InvalidOperation), $null
        if ($Details) {
            $record.ErrorDetails = New-Object -TypeName System.Management.Automation.ErrorDetails -ArgumentList $Details
        }
        $record
    }
}

AfterAll {
    Remove-Module -Name tcs.jira -Force -ErrorAction SilentlyContinue
}

Describe 'Invoke-JiraRequest' {
    BeforeEach {
        Set-JiraContext -JiraUrl "$Base/" -Username 'user@contoso.com' -PersonalAccessToken $Token
        Mock -ModuleName tcs.jira Start-Sleep { }
    }

    Context 'Context checks and parameter validation' {
        It 'Throws when Set-JiraContext has not been run' {
            InModuleScope tcs.jira {
                $script:JiraContext = $null
                $script:JiraCredential = $null
            }
            { Invoke-JiraRequest -Method Get -Resource issue -Id 'PROJ-1' } | Should -Throw '*Set-JiraContext*'
        }

        It 'Throws when no path, resource or JQL is given' {
            { Invoke-JiraRequest -Method Get } | Should -Throw '*-URIPath*'
        }

        It 'Rejects an unknown HTTP method' {
            { Invoke-JiraRequest -Method 'Fetch' -Resource issue } | Should -Throw
        }
    }

    Context 'Request construction' {
        BeforeEach {
            Mock -ModuleName tcs.jira Invoke-RestMethod { [pscustomobject]@{ key = 'PROJ-1' } }
        }

        It 'Builds the platform API URL, method and headers' {
            $result = Invoke-JiraRequest -Method Get -Resource issue -Id 'PROJ-1'
            $result.key | Should -Be 'PROJ-1'
            Should -Invoke Invoke-RestMethod -ModuleName tcs.jira -Times 1 -Exactly -ParameterFilter {
                $Uri -eq "$Base/rest/api/3/issue/PROJ-1" -and
                $Method -eq 'Get' -and
                $Headers['Authorization'] -ceq "Basic $EncodedPair" -and
                $Headers['Accept'] -eq 'application/json' -and
                -not $Headers.ContainsKey('ContentType') -and
                $ContentType -eq 'application/json; charset=utf-8' -and
                $null -eq $Body
            }
        }

        It 'Sends Service Management paths to /rest/servicedeskapi' {
            $null = Invoke-JiraRequest -Method Get -URIPath '/servicedeskapi/request/SD-1'
            Should -Invoke Invoke-RestMethod -ModuleName tcs.jira -Times 1 -Exactly -ParameterFilter {
                $Uri -eq "$Base/rest/servicedeskapi/request/SD-1"
            }
        }

        It 'Uses paths that already start with /rest/ unchanged' {
            $null = Invoke-JiraRequest -Method Get -URIPath '/rest/agile/1.0/board'
            Should -Invoke Invoke-RestMethod -ModuleName tcs.jira -Times 1 -Exactly -ParameterFilter {
                $Uri -eq "$Base/rest/agile/1.0/board"
            }
        }

        It 'Adds a leading slash to relative paths' {
            $null = Invoke-JiraRequest -Method Get -URIPath 'myself'
            Should -Invoke Invoke-RestMethod -ModuleName tcs.jira -Times 1 -Exactly -ParameterFilter {
                $Uri -eq "$Base/rest/api/3/myself"
            }
        }

        It 'Sends the body with POST' {
            $null = Invoke-JiraRequest -Method Post -Resource issue -Body '{"fields":{}}'
            Should -Invoke Invoke-RestMethod -ModuleName tcs.jira -Times 1 -Exactly -ParameterFilter {
                $Uri -eq "$Base/rest/api/3/issue" -and $Method -eq 'Post' -and $Body -eq '{"fields":{}}'
            }
        }

        It 'Encodes -Id as one path segment so it cannot change the path or add a query' {
            $null = Invoke-JiraRequest -Method Get -Resource issue -Id 'A-1?expand=changelog#x'
            $null = Invoke-JiraRequest -Method Get -Resource issue -Id 'A-1/../../myself'
            Should -Invoke Invoke-RestMethod -ModuleName tcs.jira -Times 1 -Exactly -ParameterFilter {
                $Uri.OriginalString -eq "$Base/rest/api/3/issue/A-1%3Fexpand%3Dchangelog%23x"
            }
            Should -Invoke Invoke-RestMethod -ModuleName tcs.jira -Times 1 -Exactly -ParameterFilter {
                $Uri.OriginalString -eq "$Base/rest/api/3/issue/A-1%2F..%2F..%2Fmyself"
            }
        }

        It 'Converts a hashtable body to JSON and sends a string body unchanged' {
            $null = Invoke-JiraRequest -Method Post -Resource issue -Body @{ fields = @{ summary = 'S'; labels = @('a') } }
            Should -Invoke Invoke-RestMethod -ModuleName tcs.jira -Times 1 -Exactly -ParameterFilter {
                $Body -is [string] -and ($Body | ConvertFrom-Json).fields.summary -eq 'S' -and
                (@(($Body | ConvertFrom-Json).fields.labels) -join ',') -eq 'a'
            }
        }

        It 'Converts deeply nested bodies without truncation' {
            $deep = @{ l1 = @{ l2 = @{ l3 = @{ l4 = @{ l5 = @{ l6 = @{ l7 = @{ l8 = @{ l9 = @{ l10 = @{ l11 = 'deep' } } } } } } } } } } }
            $null = Invoke-JiraRequest -Method Put -Resource issue -Id 'PROJ-1' -Body $deep
            Should -Invoke Invoke-RestMethod -ModuleName tcs.jira -Times 1 -Exactly -ParameterFilter {
                ($Body | ConvertFrom-Json).l1.l2.l3.l4.l5.l6.l7.l8.l9.l10.l11 -eq 'deep'
            }
        }

        It 'Sends -Resource search to the enhanced JQL search endpoint' {
            $null = Invoke-JiraRequest -Method Get -Resource search -Query @{ jql = 'project = P' }
            Should -Invoke Invoke-RestMethod -ModuleName tcs.jira -Times 1 -Exactly -ParameterFilter {
                $Uri.OriginalString -like "$Base/rest/api/3/search/jql?*"
            }
            { Invoke-JiraRequest -Method Get -Resource search -Id 'x' } | Should -Throw '*-Id*'
        }

        It 'URL-encodes query parameters and does not change the caller hashtable' {
            $query = @{ 'a b' = 'c&d=e' }
            $null = Invoke-JiraRequest -Method Get -URIPath '/project/search' -Query $query
            Should -Invoke Invoke-RestMethod -ModuleName tcs.jira -Times 1 -Exactly -ParameterFilter {
                $Uri.OriginalString -eq "$Base/rest/api/3/project/search?a%20b=c%26d%3De"
            }
            $query.Keys.Count | Should -Be 1
        }

        It 'Does not write the token to the verbose stream' {
            $verbose = Invoke-JiraRequest -Method Get -Resource issue -Id 'PROJ-1' -Verbose 4>&1 | Where-Object { $_ -is [System.Management.Automation.VerboseRecord] } | Out-String
            $verbose | Should -Match 'rest/api/3/issue/PROJ-1'
            $verbose | Should -Not -Match ([regex]::Escape($Token))
            $verbose | Should -Not -Match ([regex]::Escape($EncodedPair))
        }
    }

    Context 'Search and pagination' {
        It 'Uses the enhanced JQL search endpoint and unwraps issues across pages' {
            Mock -ModuleName tcs.jira Invoke-RestMethod {
                if ($Uri -match 'nextPageToken=') {
                    [pscustomobject]@{ issues = @([pscustomobject]@{ key = 'P-3' }); isLast = $true }
                }
                else {
                    [pscustomobject]@{ issues = @([pscustomobject]@{ key = 'P-1' }, [pscustomobject]@{ key = 'P-2' }); nextPageToken = 'tok/2'; isLast = $false }
                }
            }
            $query = @{ maxResults = 2 }
            $result = @(Invoke-JiraRequest -Method Get -JQL 'project = P AND status = "To Do"' -Query $query)
            ($result | ForEach-Object key) -join ',' | Should -Be 'P-1,P-2,P-3'
            Should -Invoke Invoke-RestMethod -ModuleName tcs.jira -Times 2 -Exactly
            Should -Invoke Invoke-RestMethod -ModuleName tcs.jira -Times 1 -Exactly -ParameterFilter {
                # OriginalString: [uri].ToString() would unescape the query
                $sentUri = $Uri.OriginalString
                $sentUri -like "$Base/rest/api/3/search/jql?*" -and
                $sentUri -match 'jql=project%20%3D%20P%20AND%20status%20%3D%20%22To%20Do%22' -and
                $sentUri -match 'fields=(%2A|\*)navigable' -and
                $sentUri -match 'maxResults=2' -and
                $sentUri -notmatch 'nextPageToken'
            }
            Should -Invoke Invoke-RestMethod -ModuleName tcs.jira -Times 1 -Exactly -ParameterFilter {
                $Uri.OriginalString -match 'nextPageToken=tok%2F2'
            }
            $query.ContainsKey('jql') | Should -BeFalse
        }

        It 'Keeps fields requested by the caller' {
            Mock -ModuleName tcs.jira Invoke-RestMethod { [pscustomobject]@{ issues = @(); isLast = $true } }
            $null = Invoke-JiraRequest -Method Get -JQL 'project = P' -Query @{ fields = 'summary' }
            Should -Invoke Invoke-RestMethod -ModuleName tcs.jira -Times 1 -Exactly -ParameterFilter {
                $Uri -match 'fields=summary' -and $Uri -notmatch 'navigable'
            }
        }

        It 'Stops at -MaxQueryPages and warns' {
            Mock -ModuleName tcs.jira Invoke-RestMethod { [pscustomobject]@{ issues = @([pscustomobject]@{ key = 'P-1' }); nextPageToken = 'more'; isLast = $false } }
            $result = @(Invoke-JiraRequest -Method Get -JQL 'project = P' -MaxQueryPages 3 -WarningVariable warnings -WarningAction SilentlyContinue)
            $result.Count | Should -Be 3
            Should -Invoke Invoke-RestMethod -ModuleName tcs.jira -Times 3 -Exactly
            $warnings | Should -Not -BeNullOrEmpty
        }

        It 'Unwraps multi-value pages and follows nextPage links on the same site' {
            Mock -ModuleName tcs.jira Invoke-RestMethod {
                if ($Uri -match 'startAt=50') {
                    [pscustomobject]@{ startAt = 50; maxResults = 50; isLast = $true; values = @([pscustomobject]@{ key = 'C' }) }
                }
                else {
                    [pscustomobject]@{ startAt = 0; maxResults = 50; isLast = $false; values = @([pscustomobject]@{ key = 'A' }, [pscustomobject]@{ key = 'B' }); nextPage = 'https://contoso.atlassian.net/rest/api/3/project/search?startAt=50' }
                }
            }
            $result = @(Invoke-JiraRequest -Method Get -URIPath '/project/search')
            $result.Count | Should -Be 3
            ($result | ForEach-Object key) -join ',' | Should -Be 'A,B,C'
            Should -Invoke Invoke-RestMethod -ModuleName tcs.jira -Times 2 -Exactly
            Should -Invoke Invoke-RestMethod -ModuleName tcs.jira -Times 1 -Exactly -ParameterFilter {
                $Uri -eq 'https://contoso.atlassian.net/rest/api/3/project/search?startAt=50'
            }
        }

        It 'Does not follow nextPage when the page says it is the last one' {
            Mock -ModuleName tcs.jira Invoke-RestMethod { [pscustomobject]@{ isLast = $true; values = @(1, 2); nextPage = 'https://contoso.atlassian.net/rest/api/3/project/search?startAt=2' } }
            $result = @(Invoke-JiraRequest -Method Get -URIPath '/project/search')
            $result.Count | Should -Be 2
            Should -Invoke Invoke-RestMethod -ModuleName tcs.jira -Times 1 -Exactly
        }

        It 'Unwraps Service Management pages and follows _links.next until isLastPage' {
            Mock -ModuleName tcs.jira Invoke-RestMethod {
                if ($Uri -match 'start=2') {
                    [pscustomobject]@{ size = 1; start = 2; limit = 2; isLastPage = $true; values = @([pscustomobject]@{ id = '3' }); _links = [pscustomobject]@{ base = 'https://contoso.atlassian.net/rest/servicedeskapi' } }
                }
                else {
                    [pscustomobject]@{ size = 2; start = 0; limit = 2; isLastPage = $false; values = @([pscustomobject]@{ id = '1' }, [pscustomobject]@{ id = '2' }); _links = [pscustomobject]@{ next = 'https://contoso.atlassian.net/rest/servicedeskapi/servicedesk?start=2&limit=2' } }
                }
            }
            $result = @(Invoke-JiraRequest -Method Get -URIPath '/servicedeskapi/servicedesk')
            ($result | ForEach-Object id) -join ',' | Should -Be '1,2,3'
            Should -Invoke Invoke-RestMethod -ModuleName tcs.jira -Times 2 -Exactly
            Should -Invoke Invoke-RestMethod -ModuleName tcs.jira -Times 1 -Exactly -ParameterFilter {
                $Uri -eq 'https://contoso.atlassian.net/rest/servicedeskapi/servicedesk?start=2&limit=2'
            }
        }

        It 'Stops Service Management paging at -MaxQueryPages and warns' {
            Mock -ModuleName tcs.jira Invoke-RestMethod { [pscustomobject]@{ isLastPage = $false; values = @('a'); _links = [pscustomobject]@{ next = 'https://contoso.atlassian.net/rest/servicedeskapi/request?start=1' } } }
            $result = @(Invoke-JiraRequest -Method Get -URIPath '/servicedeskapi/request' -MaxQueryPages 2 -WarningVariable warnings -WarningAction SilentlyContinue)
            $result.Count | Should -Be 2
            Should -Invoke Invoke-RestMethod -ModuleName tcs.jira -Times 2 -Exactly
            $warnings | Should -Not -BeNullOrEmpty
        }

        It 'Does not follow a Service Management link to another host' {
            Mock -ModuleName tcs.jira Invoke-RestMethod { [pscustomobject]@{ isLastPage = $false; values = @('a'); _links = [pscustomobject]@{ next = 'https://evil.example.com/rest/servicedeskapi/request?start=1' } } }
            $null = Invoke-JiraRequest -Method Get -URIPath '/servicedeskapi/request' -WarningAction SilentlyContinue
            Should -Invoke Invoke-RestMethod -ModuleName tcs.jira -Times 1 -Exactly
        }

        It 'Returns responses with an issues property unchanged outside search (bulk create errors)' {
            Mock -ModuleName tcs.jira Invoke-RestMethod {
                [pscustomobject]@{
                    issues = @([pscustomobject]@{ id = '1'; key = 'P-1' })
                    errors = @([pscustomobject]@{ status = 400; failedElementNumber = 1; elementErrors = [pscustomobject]@{ errors = [pscustomobject]@{ summary = 'required' } } })
                }
            }
            $result = @(Invoke-JiraRequest -Method Post -URIPath '/issue/bulk' -Body @{ issueUpdates = @() })
            $result.Count | Should -Be 1
            @($result[0].issues).Count | Should -Be 1
            @($result[0].errors).Count | Should -Be 1
            $result[0].errors[0].failedElementNumber | Should -Be 1
        }

        It 'Returns the untouched search response with -Raw and makes one request' {
            Mock -ModuleName tcs.jira Invoke-RestMethod { [pscustomobject]@{ issues = @([pscustomobject]@{ key = 'P-1' }); nextPageToken = 'more'; isLast = $false; names = [pscustomobject]@{ summary = 'Summary' } } }
            $result = @(Invoke-JiraRequest -Method Get -JQL 'project = P' -Raw)
            $result.Count | Should -Be 1
            $result[0].nextPageToken | Should -Be 'more'
            $result[0].names.summary | Should -Be 'Summary'
            $result[0].issues[0].key | Should -Be 'P-1'
            Should -Invoke Invoke-RestMethod -ModuleName tcs.jira -Times 1 -Exactly
        }

        It 'Returns an untouched page with -Raw' {
            Mock -ModuleName tcs.jira Invoke-RestMethod { [pscustomobject]@{ isLast = $false; values = @(1, 2); nextPage = 'https://contoso.atlassian.net/rest/api/3/project/search?startAt=2' } }
            $result = @(Invoke-JiraRequest -Method Get -URIPath '/project/search' -Raw)
            $result.Count | Should -Be 1
            @($result[0].values).Count | Should -Be 2
            Should -Invoke Invoke-RestMethod -ModuleName tcs.jira -Times 1 -Exactly
        }

        It 'Does not send credentials to a nextPage link on another host' {
            Mock -ModuleName tcs.jira Invoke-RestMethod { [pscustomobject]@{ values = @(1); nextPage = 'https://evil.example.com/steal' } }
            $null = Invoke-JiraRequest -Method Get -URIPath '/project/search' -WarningAction SilentlyContinue
            Should -Invoke Invoke-RestMethod -ModuleName tcs.jira -Times 1 -Exactly
            Should -Invoke Invoke-RestMethod -ModuleName tcs.jira -Times 0 -Exactly -ParameterFilter { $Uri -like 'https://evil*' }
        }

        It 'Returns the elements of a JSON array response' {
            Mock -ModuleName tcs.jira Invoke-RestMethod { , @([pscustomobject]@{ accountId = 'a' }, [pscustomobject]@{ accountId = 'b' }) }
            $result = @(Invoke-JiraRequest -Method Get -URIPath '/user/search' -Query @{ query = 'x' })
            $result.Count | Should -Be 2
            $result[1].accountId | Should -Be 'b'
        }

        It 'Returns nothing for an empty (204) response' {
            Mock -ModuleName tcs.jira Invoke-RestMethod { '' }
            $result = Invoke-JiraRequest -Method Put -Resource issue -Id 'PROJ-1' -Body '{}'
            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Error handling' {
        It 'Retries HTTP 503 and 429 responses, then returns the result' {
            $script:calls = 0
            Mock -ModuleName tcs.jira Invoke-RestMethod {
                $script:calls++
                if ($script:calls -eq 1) { throw (New-HttpError -StatusCode 503) }
                if ($script:calls -eq 2) { throw (New-HttpError -StatusCode 429) }
                [pscustomobject]@{ key = 'PROJ-1' }
            }
            $result = Invoke-JiraRequest -Method Get -Resource issue -Id 'PROJ-1' -WarningAction SilentlyContinue
            $result.key | Should -Be 'PROJ-1'
            Should -Invoke Invoke-RestMethod -ModuleName tcs.jira -Times 3 -Exactly
            Should -Invoke Start-Sleep -ModuleName tcs.jira -Times 2 -Exactly
        }

        It 'Does not retry a POST on HTTP 503, so an issue is never created twice' {
            Mock -ModuleName tcs.jira Invoke-RestMethod { throw (New-HttpError -StatusCode 503) }
            { Invoke-JiraRequest -Method Post -Resource issue -Body @{ fields = @{} } -WarningAction SilentlyContinue } | Should -Throw '*HTTP status code: 503*'
            Should -Invoke Invoke-RestMethod -ModuleName tcs.jira -Times 1 -Exactly
            Should -Invoke Start-Sleep -ModuleName tcs.jira -Times 0 -Exactly
        }

        It 'Does not retry a POST on HTTP 500 or a PATCH on HTTP 502' {
            Mock -ModuleName tcs.jira Invoke-RestMethod { throw (New-HttpError -StatusCode 500) }
            { Invoke-JiraRequest -Method Post -URIPath '/issue/PROJ-1/comment' -Body '{}' } | Should -Throw '*HTTP status code: 500*'
            Mock -ModuleName tcs.jira Invoke-RestMethod { throw (New-HttpError -StatusCode 502) }
            { Invoke-JiraRequest -Method Patch -URIPath '/thing' -Body '{}' } | Should -Throw '*HTTP status code: 502*'
            Should -Invoke Invoke-RestMethod -ModuleName tcs.jira -Times 2 -Exactly
        }

        It 'Retries a POST on HTTP 429' {
            $script:calls = 0
            Mock -ModuleName tcs.jira Invoke-RestMethod {
                $script:calls++
                if ($script:calls -eq 1) { throw (New-HttpError -StatusCode 429) }
                [pscustomobject]@{ key = 'PROJ-2' }
            }
            $result = Invoke-JiraRequest -Method Post -Resource issue -Body '{}' -WarningAction SilentlyContinue
            $result.key | Should -Be 'PROJ-2'
            Should -Invoke Invoke-RestMethod -ModuleName tcs.jira -Times 2 -Exactly
        }

        It 'Retries PUT and DELETE on HTTP 5xx' {
            Mock -ModuleName tcs.jira Invoke-RestMethod { throw (New-HttpError -StatusCode 500) }
            { Invoke-JiraRequest -Method Put -Resource issue -Id 'PROJ-1' -Body '{}' -WarningAction SilentlyContinue } | Should -Throw
            { Invoke-JiraRequest -Method Delete -Resource issue -Id 'PROJ-1' -WarningAction SilentlyContinue } | Should -Throw
            Should -Invoke Invoke-RestMethod -ModuleName tcs.jira -Times 6 -Exactly
        }

        It 'Waits for the Retry-After header' {
            $script:calls = 0
            Mock -ModuleName tcs.jira Invoke-RestMethod {
                $script:calls++
                if ($script:calls -eq 1) { throw (New-HttpError -StatusCode 429 -Headers @{ 'Retry-After' = '7' }) }
                [pscustomobject]@{ key = 'PROJ-1' }
            }
            $null = Invoke-JiraRequest -Method Get -Resource issue -Id 'PROJ-1' -WarningAction SilentlyContinue
            Should -Invoke Start-Sleep -ModuleName tcs.jira -Times 1 -Exactly -ParameterFilter { $Seconds -eq 7 }
        }

        It 'Backs off 2 then 4 seconds without Retry-After' {
            Mock -ModuleName tcs.jira Invoke-RestMethod { throw (New-HttpError -StatusCode 503) }
            { Invoke-JiraRequest -Method Get -Resource issue -Id 'PROJ-1' -WarningAction SilentlyContinue } | Should -Throw
            Should -Invoke Start-Sleep -ModuleName tcs.jira -Times 1 -Exactly -ParameterFilter { $Seconds -eq 2 }
            Should -Invoke Start-Sleep -ModuleName tcs.jira -Times 1 -Exactly -ParameterFilter { $Seconds -eq 4 }
        }

        It 'Gives up after three attempts' {
            Mock -ModuleName tcs.jira Invoke-RestMethod { throw (New-HttpError -StatusCode 503) }
            { Invoke-JiraRequest -Method Get -Resource issue -Id 'PROJ-1' -WarningAction SilentlyContinue } | Should -Throw '*HTTP status code: 503*'
            Should -Invoke Invoke-RestMethod -ModuleName tcs.jira -Times 3 -Exactly
        }

        It 'Does not retry client errors and includes the status and Jira details' {
            Mock -ModuleName tcs.jira Invoke-RestMethod { throw (New-HttpError -StatusCode 404 -Details '{"errorMessages":["Issue does not exist"]}') }
            $caught = $null
            try {
                Invoke-JiraRequest -Method Get -Resource issue -Id 'PROJ-404'
            }
            catch {
                $caught = $_
            }
            $caught | Should -Not -BeNullOrEmpty
            $caught.FullyQualifiedErrorId | Should -BeLike 'JiraRequestFailed*'
            $caught.Exception.Message | Should -Match 'HTTP status code: 404'
            $caught.Exception.Message | Should -Match 'Issue does not exist'
            $caught.Exception.Message | Should -Match 'PROJ-404'
            $caught.Exception.InnerException | Should -Not -BeNullOrEmpty
            Should -Invoke Invoke-RestMethod -ModuleName tcs.jira -Times 1 -Exactly
            Should -Invoke Start-Sleep -ModuleName tcs.jira -Times 0 -Exactly
        }

        It 'Never includes the token in the error' {
            Mock -ModuleName tcs.jira Invoke-RestMethod { throw (New-HttpError -StatusCode 401 -Details 'Unauthorized') }
            $caught = $null
            try {
                Invoke-JiraRequest -Method Get -Resource issue -Id 'PROJ-1' -Verbose 4>$null
            }
            catch {
                $caught = $_
            }
            $text = ($caught | Out-String) + $caught.Exception.ToString()
            $text | Should -Not -Match ([regex]::Escape($Token))
            $text | Should -Not -Match ([regex]::Escape($EncodedPair))
        }
    }
}
