BeforeAll {
    $env:TCS_CONFIG_ROOT = Join-Path -Path $TestDrive -ChildPath 'config'
    $env:TCS_SKIP_UPDATE_CHECK = '1'
    $env:TCS_TELEMETRY_OPTOUT = '1'
    $ModuleRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
    Import-Module -Name (Join-Path -Path $ModuleRoot -ChildPath 'tcs.jira.psd1') -Force
    Set-JiraContext -JiraUrl 'https://contoso.atlassian.net' -Username 'user@contoso.com' -PersonalAccessToken 'tok-SECRET-123'
    $Base = 'https://contoso.atlassian.net'
}

AfterAll {
    Remove-Module -Name tcs.jira -Force -ErrorAction SilentlyContinue
}

Describe 'Find-JiraIssue' {
    BeforeEach {
        Mock -ModuleName tcs.jira Invoke-RestMethod {
            if ($Uri -match 'nextPageToken=t2') {
                [pscustomobject]@{ issues = @([pscustomobject]@{ id = '3'; key = 'P-3' }); isLast = $true }
            }
            else {
                [pscustomobject]@{ issues = @([pscustomobject]@{ id = '1'; key = 'P-1' }, [pscustomobject]@{ id = '2'; key = 'P-2' }); nextPageToken = 't2'; isLast = $false }
            }
        }
    }

    It 'Returns the issues of every page from the enhanced search endpoint' {
        $issues = @(Find-JiraIssue -JQL 'project = P' -Fields summary, status)
        ($issues | ForEach-Object key) -join ',' | Should -Be 'P-1,P-2,P-3'
        Should -Invoke Invoke-RestMethod -ModuleName tcs.jira -Times 2 -Exactly
        Should -Invoke Invoke-RestMethod -ModuleName tcs.jira -Times 1 -Exactly -ParameterFilter {
            $sent = $Uri.OriginalString
            $sent -like "$Base/rest/api/3/search/jql?*" -and $sent -match 'jql=project%20%3D%20P' -and
            $sent -match 'fields=summary%2Cstatus' -and $sent -match 'maxResults=100' -and $sent -notmatch 'nextPageToken'
        }
    }

    It 'Stops at -MaxResults without requesting more pages' {
        $issues = @(Find-JiraIssue -JQL 'project = P' -MaxResults 2 -WarningVariable warnings)
        ($issues | ForEach-Object key) -join ',' | Should -Be 'P-1,P-2'
        Should -Invoke Invoke-RestMethod -ModuleName tcs.jira -Times 1 -Exactly -ParameterFilter { $Uri.OriginalString -match 'maxResults=2' }
        Should -Invoke Invoke-RestMethod -ModuleName tcs.jira -Times 1 -Exactly
        $warnings | Should -BeNullOrEmpty
    }

    It 'Requests navigable fields by default' {
        $null = Find-JiraIssue -JQL 'project = P' -MaxResults 1
        Should -Invoke Invoke-RestMethod -ModuleName tcs.jira -Times 1 -Exactly -ParameterFilter { $Uri.OriginalString -match 'fields=%2Anavigable' }
    }

    It 'Pipes into Update-JiraTicket' {
        Find-JiraIssue -JQL 'project = P' | Update-JiraTicket -Comment 'Bulk comment'
        foreach ($key in 'P-1', 'P-2', 'P-3') {
            Should -Invoke Invoke-RestMethod -ModuleName tcs.jira -Times 1 -Exactly -ParameterFilter { $Uri -eq "$Base/rest/api/3/issue/$key/comment" -and $Method -eq 'Post' }
        }
    }

    It 'Pipes into Get-JiraTicket and Update-JSMRequest' {
        $null = Find-JiraIssue -JQL 'project = P' -MaxResults 1 | Get-JiraTicket
        Should -Invoke Invoke-RestMethod -ModuleName tcs.jira -Times 1 -Exactly -ParameterFilter { $Uri -eq "$Base/rest/api/3/issue/P-1" -and $Method -eq 'Get' }
        Find-JiraIssue -JQL 'project = P' -MaxResults 1 | Update-JSMRequest -Comment 'Hi' -Internal
        Should -Invoke Invoke-RestMethod -ModuleName tcs.jira -Times 1 -Exactly -ParameterFilter { $Uri -eq "$Base/rest/servicedeskapi/request/P-1/comment" }
    }
}
