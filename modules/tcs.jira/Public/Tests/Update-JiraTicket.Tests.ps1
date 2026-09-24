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

Describe 'Update-JiraTicket' {
    BeforeEach {
        Mock -ModuleName tcs.jira Invoke-RestMethod {
            if ($Method -eq 'Get' -and $Uri -like '*/transitions') {
                return [pscustomobject]@{ transitions = @(
                        [pscustomobject]@{ id = '11'; name = 'Undone work' },
                        [pscustomobject]@{ id = '31'; name = 'Done' },
                        [pscustomobject]@{ id = '41'; name = 'Resolved' }
                    )
                }
            }
            if ($Uri -like '*/comment') {
                return [pscustomobject]@{ id = '500' }
            }
        }
    }

    It 'Throws when there is nothing to update' {
        { Update-JiraTicket -IssueKey 'PROJ-1' } | Should -Throw '*at least one*'
        Should -Invoke Invoke-RestMethod -ModuleName tcs.jira -Times 0 -Exactly
    }

    It 'Performs the exact Done transition' {
        Update-JiraTicket -IssueKey 'PROJ-1' -MarkDone
        Should -Invoke Invoke-RestMethod -ModuleName tcs.jira -Times 1 -Exactly -ParameterFilter {
            $Uri -eq "$Base/rest/api/3/issue/PROJ-1/transitions" -and $Method -eq 'Get'
        }
        Should -Invoke Invoke-RestMethod -ModuleName tcs.jira -Times 1 -Exactly -ParameterFilter {
            $Uri -eq "$Base/rest/api/3/issue/PROJ-1/transitions" -and $Method -eq 'Post' -and
            ($Body | ConvertFrom-Json).transition.id -eq '31'
        }
    }

    It 'Performs the Resolved transition' {
        Update-JiraTicket -IssueKey 'PROJ-1' -MarkResolved
        Should -Invoke Invoke-RestMethod -ModuleName tcs.jira -Times 1 -Exactly -ParameterFilter {
            $Method -eq 'Post' -and ($Body | ConvertFrom-Json).transition.id -eq '41'
        }
    }

    It 'Warns when no matching transition exists' {
        Mock -ModuleName tcs.jira Invoke-RestMethod { [pscustomobject]@{ transitions = @([pscustomobject]@{ id = '1'; name = 'Start' }) } }
        Update-JiraTicket -IssueKey 'PROJ-1' -MarkDone -WarningVariable warnings -WarningAction SilentlyContinue
        $warnings | Should -Not -BeNullOrEmpty
        Should -Invoke Invoke-RestMethod -ModuleName tcs.jira -Times 0 -Exactly -ParameterFilter { $Method -eq 'Post' }
    }

    It 'Updates summary and optional fields with one PUT' {
        Update-JiraTicket -IssueKey 'PROJ-1' -Summary 'New title' -OptionalFields @{ labels = @('ops', 'urgent') }
        Should -Invoke Invoke-RestMethod -ModuleName tcs.jira -Times 1 -Exactly -ParameterFilter {
            $sent = if ($Body) { $Body | ConvertFrom-Json } else { [pscustomobject]@{} }
            $Uri -eq "$Base/rest/api/3/issue/PROJ-1" -and $Method -eq 'Put' -and
            $sent.fields.summary -eq 'New title' -and
            (@($sent.fields.labels) -join ',') -eq 'ops,urgent'
        }
    }

    It 'Adds a comment as an ADF document' {
        Update-JiraTicket -IssueKey 'PROJ-1' -Comment 'Deployed'
        Should -Invoke Invoke-RestMethod -ModuleName tcs.jira -Times 1 -Exactly -ParameterFilter {
            $sent = if ($Body) { $Body | ConvertFrom-Json } else { [pscustomobject]@{} }
            $Uri -eq "$Base/rest/api/3/issue/PROJ-1/comment" -and $Method -eq 'Post' -and
            $sent.body.type -eq 'doc' -and
            $sent.body.content[0].content[0].text -eq 'Deployed'
        }
    }

    It 'Writes nothing to the pipeline or the host' {
        $output = Update-JiraTicket -IssueKey 'PROJ-1' -Comment 'Deployed' -MarkDone 6>&1
        $output | Should -BeNullOrEmpty
    }

    It 'Does not call Jira with -WhatIf' {
        Update-JiraTicket -IssueKey 'PROJ-1' -Summary 'S' -Comment 'C' -MarkDone -WhatIf
        Should -Invoke Invoke-RestMethod -ModuleName tcs.jira -Times 0 -Exactly
    }

    It 'Writes a non-terminating error for a failed field update and still adds the comment' {
        Mock -ModuleName tcs.jira Invoke-RestMethod { throw 'Field is not on the screen' } -ParameterFilter { $Method -eq 'Put' }
        Update-JiraTicket -IssueKey 'PROJ-1' -Summary 'S' -Comment 'C' -ErrorVariable errors -ErrorAction SilentlyContinue
        @($errors).Count | Should -BeGreaterThan 0
        ($errors | Out-String) | Should -Match 'Failed to update fields'
        Should -Invoke Invoke-RestMethod -ModuleName tcs.jira -Times 1 -Exactly -ParameterFilter { $Uri -like '*/comment' }
    }

    It 'Stops on a failed field update with -ErrorAction Stop' {
        Mock -ModuleName tcs.jira Invoke-RestMethod { throw 'Field is not on the screen' } -ParameterFilter { $Method -eq 'Put' }
        { Update-JiraTicket -IssueKey 'PROJ-1' -Summary 'S' -ErrorAction Stop } | Should -Throw '*Failed to update fields*'
    }

    It 'Throws when the comment cannot be added' {
        Mock -ModuleName tcs.jira Invoke-RestMethod { throw 'Forbidden' } -ParameterFilter { $Uri -like '*/comment' }
        { Update-JiraTicket -IssueKey 'PROJ-1' -Comment 'C' } | Should -Throw '*Failed to add comment*'
    }
}

Describe 'Update-JiraTicket telemetry' {
    BeforeEach {
        Mock -ModuleName tcs.jira Invoke-RestMethod { [pscustomobject]@{ id = '500' } }
        Mock -ModuleName tcs.jira Invoke-TelemetryCollection { }
    }

    It 'Sends Start and End events for a successful update' {
        Update-JiraTicket -IssueKey 'PROJ-1' -Comment 'Hello'
        Should -Invoke Invoke-TelemetryCollection -ModuleName tcs.jira -Times 1 -Exactly -ParameterFilter {
            $CommandName -eq 'Update-JiraTicket' -and $Stage -eq 'Start'
        }
        Should -Invoke Invoke-TelemetryCollection -ModuleName tcs.jira -Times 1 -Exactly -ParameterFilter {
            $CommandName -eq 'Update-JiraTicket' -and $Stage -eq 'End' -and -not $Failed
        }
    }

    It 'Sends a failed End event and rethrows when there is nothing to update' {
        { Update-JiraTicket -IssueKey 'PROJ-1' } | Should -Throw '*at least one*'
        Should -Invoke Invoke-TelemetryCollection -ModuleName tcs.jira -Times 1 -Exactly -ParameterFilter {
            $CommandName -eq 'Update-JiraTicket' -and $Stage -eq 'End' -and $Failed -eq $true
        }
    }

    It 'Sends a failed End event when adding the comment fails' {
        Mock -ModuleName tcs.jira Invoke-RestMethod { throw 'Server error' }
        { Update-JiraTicket -IssueKey 'PROJ-1' -Comment 'Hello' } | Should -Throw '*Failed to add comment*'
        Should -Invoke Invoke-TelemetryCollection -ModuleName tcs.jira -Times 1 -Exactly -ParameterFilter {
            $CommandName -eq 'Update-JiraTicket' -and $Stage -eq 'End' -and $Failed -eq $true
        }
        Should -Invoke Invoke-TelemetryCollection -ModuleName tcs.jira -Times 0 -Exactly -ParameterFilter {
            $CommandName -eq 'Update-JiraTicket' -and $Stage -eq 'End' -and -not $Failed
        }
    }
}
