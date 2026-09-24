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

Describe 'Update-JSMRequest' {
    BeforeEach {
        Mock -ModuleName tcs.jira Invoke-RestMethod {
            if ($Method -eq 'Get' -and $Uri -like '*/transition') {
                return [pscustomobject]@{ size = 2; isLastPage = $true; values = @(
                        [pscustomobject]@{ id = '5'; name = 'Cancel request' },
                        [pscustomobject]@{ id = '761'; name = 'Done' }
                    )
                }
            }
        }
    }

    It 'Throws when there is nothing to update' {
        { Update-JSMRequest -IssueKey 'SD-1' } | Should -Throw '*at least one*'
    }

    It 'Performs the Done customer transition with the Service Management body' {
        Update-JSMRequest -IssueKey 'SD-1' -MarkDone
        Should -Invoke Invoke-RestMethod -ModuleName tcs.jira -Times 1 -Exactly -ParameterFilter {
            $Uri -eq "$Base/rest/servicedeskapi/request/SD-1/transition" -and $Method -eq 'Get'
        }
        Should -Invoke Invoke-RestMethod -ModuleName tcs.jira -Times 1 -Exactly -ParameterFilter {
            $sent = if ($Body) { $Body | ConvertFrom-Json } else { [pscustomobject]@{} }
            $Uri -eq "$Base/rest/servicedeskapi/request/SD-1/transition" -and $Method -eq 'Post' -and
            $sent.id -eq '761' -and -not ($sent.PSObject.Properties.Name -contains 'transition')
        }
    }

    It 'Updates fields through the platform issue API' {
        Update-JSMRequest -IssueKey 'SD-1' -Summary 'New title' -OptionalFields @{ priority = @{ name = 'High' } }
        Should -Invoke Invoke-RestMethod -ModuleName tcs.jira -Times 1 -Exactly -ParameterFilter {
            $sent = if ($Body) { $Body | ConvertFrom-Json } else { [pscustomobject]@{} }
            $Uri -eq "$Base/rest/api/3/issue/SD-1" -and $Method -eq 'Put' -and
            $sent.fields.summary -eq 'New title' -and $sent.fields.priority.name -eq 'High'
        }
    }

    It 'Adds a public comment through the Service Management API' {
        Update-JSMRequest -IssueKey 'SD-1' -Comment 'Shipped'
        Should -Invoke Invoke-RestMethod -ModuleName tcs.jira -Times 1 -Exactly -ParameterFilter {
            $sent = if ($Body) { $Body | ConvertFrom-Json } else { [pscustomobject]@{} }
            $Uri -eq "$Base/rest/servicedeskapi/request/SD-1/comment" -and $Method -eq 'Post' -and
            $sent.body -eq 'Shipped' -and $sent.public -eq $true
        }
        Should -Invoke Invoke-RestMethod -ModuleName tcs.jira -Times 0 -Exactly -ParameterFilter { $Uri -like '*/rest/api/3/*' }
    }

    It 'Adds an internal comment with -Internal' {
        Update-JSMRequest -IssueKey 'SD-1' -Comment 'Agents only' -Internal
        Should -Invoke Invoke-RestMethod -ModuleName tcs.jira -Times 1 -Exactly -ParameterFilter {
            $sent = if ($Body) { $Body | ConvertFrom-Json } else { [pscustomobject]@{} }
            $Uri -eq "$Base/rest/servicedeskapi/request/SD-1/comment" -and $sent.public -eq $false
        }
    }

    It 'Rethrows the original error record when the comment cannot be added' {
        Mock -ModuleName tcs.jira Invoke-RestMethod { throw 'Forbidden' } -ParameterFilter { $Uri -like '*/comment' }
        $caught = $null
        try { Update-JSMRequest -IssueKey 'SD-1' -Comment 'C' } catch { $caught = $_ }
        $caught.FullyQualifiedErrorId | Should -BeLike 'JiraRequestFailed*'
        $caught.Exception.Message | Should -Match 'Forbidden'
    }

    It 'Writes an error listing the transitions when there is no Done transition' {
        Mock -ModuleName tcs.jira Invoke-RestMethod { [pscustomobject]@{ isLastPage = $true; values = @([pscustomobject]@{ id = '5'; name = 'Cancel request' }, [pscustomobject]@{ id = '6'; name = 'Not Done' }) } }
        Update-JSMRequest -IssueKey 'SD-1' -MarkDone -ErrorVariable errors -ErrorAction SilentlyContinue
        $failed = @($errors | Where-Object { $_.FullyQualifiedErrorId -like 'JiraTransitionFailed*' })
        $failed.Count | Should -Be 1
        $failed[0].Exception.Message | Should -Match "'Cancel request', 'Not Done'"
        Should -Invoke Invoke-RestMethod -ModuleName tcs.jira -Times 0 -Exactly -ParameterFilter { $Method -eq 'Post' }
    }

    It 'Takes issue keys from the pipeline by property name' {
        [pscustomobject]@{ Key = 'SD-7' } | Update-JSMRequest -Summary 'Piped'
        Should -Invoke Invoke-RestMethod -ModuleName tcs.jira -Times 1 -Exactly -ParameterFilter { $Uri -eq "$Base/rest/api/3/issue/SD-7" -and $Method -eq 'Put' }
    }

    It 'Rejects issue keys that could change the request path' {
        { Update-JSMRequest -IssueKey 'SD-1/../../x' -Comment 'x' } | Should -Throw
        Should -Invoke Invoke-RestMethod -ModuleName tcs.jira -Times 0 -Exactly
    }

    It 'Writes nothing to the pipeline or the host' {
        $output = Update-JSMRequest -IssueKey 'SD-1' -Comment 'Shipped' -MarkDone 6>&1
        $output | Should -BeNullOrEmpty
    }

    It 'Does not call Jira with -WhatIf' {
        Update-JSMRequest -IssueKey 'SD-1' -Summary 'S' -Comment 'C' -MarkDone -WhatIf
        Should -Invoke Invoke-RestMethod -ModuleName tcs.jira -Times 0 -Exactly
    }

    It 'Writes a non-terminating error when the transition fails' {
        Mock -ModuleName tcs.jira Invoke-RestMethod { throw 'Nope' } -ParameterFilter { $Method -eq 'Get' }
        Update-JSMRequest -IssueKey 'SD-1' -MarkDone -ErrorVariable errors -ErrorAction SilentlyContinue
        ($errors | Out-String) | Should -Match 'Failed to transition'
    }
}
