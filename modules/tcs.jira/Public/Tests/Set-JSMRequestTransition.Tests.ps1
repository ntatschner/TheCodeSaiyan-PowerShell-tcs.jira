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

Describe 'Set-JSMRequestTransition' {
    BeforeEach {
        Mock -ModuleName tcs.jira Invoke-RestMethod { }
    }

    It 'Posts the transition id to the Service Management API' {
        $output = Set-JSMRequestTransition -IssueKey 'SD-42' -TransitionId '761'
        $output | Should -BeNullOrEmpty
        Should -Invoke Invoke-RestMethod -ModuleName tcs.jira -Times 1 -Exactly -ParameterFilter {
            $sent = if ($Body) { $Body | ConvertFrom-Json } else { [pscustomobject]@{} }
            $Uri -eq "$Base/rest/servicedeskapi/request/SD-42/transition" -and $Method -eq 'Post' -and
            $sent.id -eq '761'
        }
    }

    It 'Rejects keys and transition ids that could change the request path' {
        { Set-JSMRequestTransition -IssueKey 'SD-42/../x' -TransitionId '761' } | Should -Throw
        { Set-JSMRequestTransition -IssueKey 'SD-42' -TransitionId '761/x' } | Should -Throw
        Should -Invoke Invoke-RestMethod -ModuleName tcs.jira -Times 0 -Exactly
    }

    It 'Does not call Jira with -WhatIf' {
        Set-JSMRequestTransition -IssueKey 'SD-42' -TransitionId '761' -WhatIf
        Should -Invoke Invoke-RestMethod -ModuleName tcs.jira -Times 0 -Exactly
    }

    It 'Propagates request errors' {
        Mock -ModuleName tcs.jira Invoke-RestMethod { throw 'Bad transition' }
        { Set-JSMRequestTransition -IssueKey 'SD-42' -TransitionId '1' } | Should -Throw '*Bad transition*'
    }
}
