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

Describe 'Get-JiraIssueTransition' {
    It 'Returns the transitions of an issue' {
        Mock -ModuleName tcs.jira Invoke-RestMethod { [pscustomobject]@{ transitions = @([pscustomobject]@{ id = '1'; name = 'Start'; to = [pscustomobject]@{ name = 'In Progress' } }, [pscustomobject]@{ id = '2'; name = 'Finish'; to = [pscustomobject]@{ name = 'Done' } }) } }
        $transitions = @(Get-JiraIssueTransition -IssueKey 'PROJ-1')
        $transitions.Count | Should -Be 2
        $transitions[1].to.name | Should -Be 'Done'
        Should -Invoke Invoke-RestMethod -ModuleName tcs.jira -Times 1 -Exactly -ParameterFilter { $Uri -eq "$Base/rest/api/3/issue/PROJ-1/transitions" -and $Method -eq 'Get' }
    }

    It 'Rejects issue keys that could change the request path' {
        Mock -ModuleName tcs.jira Invoke-RestMethod { }
        { Get-JiraIssueTransition -IssueKey 'PROJ-1/../x' } | Should -Throw
        Should -Invoke Invoke-RestMethod -ModuleName tcs.jira -Times 0 -Exactly
    }
}

Describe 'Invoke-JiraIssueTransition' {
    BeforeEach {
        Mock -ModuleName tcs.jira Invoke-RestMethod {
            if ($Method -eq 'Get') {
                return [pscustomobject]@{ transitions = @(
                        [pscustomobject]@{ id = '11'; name = 'Not Done'; to = [pscustomobject]@{ name = "Won't Do" } },
                        [pscustomobject]@{ id = '21'; name = 'Start Progress'; to = [pscustomobject]@{ name = 'In Progress' } },
                        [pscustomobject]@{ id = '31'; name = 'Complete'; to = [pscustomobject]@{ name = 'Done' } }
                    )
                }
            }
        }
    }

    It 'Performs the transition that leads to the status' {
        Invoke-JiraIssueTransition -IssueKey 'PROJ-1' -Status 'in progress'
        Should -Invoke Invoke-RestMethod -ModuleName tcs.jira -Times 1 -Exactly -ParameterFilter {
            $Uri -eq "$Base/rest/api/3/issue/PROJ-1/transitions" -and $Method -eq 'Post' -and ($Body | ConvertFrom-Json).transition.id -eq '21'
        }
    }

    It 'Adds a comment after the transition and returns the transition with -PassThru' {
        $result = Invoke-JiraIssueTransition -IssueKey 'PROJ-1' -Status 'Done' -Comment 'Finished' -PassThru
        $result.id | Should -Be '31'
        Should -Invoke Invoke-RestMethod -ModuleName tcs.jira -Times 1 -Exactly -ParameterFilter {
            $Uri -eq "$Base/rest/api/3/issue/PROJ-1/comment" -and ($Body | ConvertFrom-Json).body.content[0].content[0].text -eq 'Finished'
        }
    }

    It 'Throws a clear error listing the available transitions' {
        $caught = $null
        try { Invoke-JiraIssueTransition -IssueKey 'PROJ-1' -Status 'Resolved' } catch { $caught = $_ }
        $caught.FullyQualifiedErrorId | Should -BeLike 'JiraTransitionNotFound*'
        $caught.Exception.Message | Should -Match "No transition to status 'Resolved' is available for PROJ-1"
        $caught.Exception.Message | Should -Match "'Complete' \(to 'Done'\)"
        Should -Invoke Invoke-RestMethod -ModuleName tcs.jira -Times 0 -Exactly -ParameterFilter { $Method -eq 'Post' }
    }

    It 'Does not call Jira with -WhatIf' {
        Invoke-JiraIssueTransition -IssueKey 'PROJ-1' -Status 'Done' -WhatIf
        Should -Invoke Invoke-RestMethod -ModuleName tcs.jira -Times 0 -Exactly
    }

    It 'Takes issue keys from the pipeline' {
        [pscustomobject]@{ key = 'PROJ-9' } | Invoke-JiraIssueTransition -Status 'Done'
        Should -Invoke Invoke-RestMethod -ModuleName tcs.jira -Times 1 -Exactly -ParameterFilter { $Uri -eq "$Base/rest/api/3/issue/PROJ-9/transitions" -and $Method -eq 'Post' }
    }
}
