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

Describe 'New-JiraTicket' {
    BeforeEach {
        Mock -ModuleName tcs.jira Invoke-RestMethod { [pscustomobject]@{ id = '1'; key = 'PROJ-1' } }
    }

    It 'Posts the fields to /rest/api/3/issue and returns the result' {
        $result = New-JiraTicket -ProjectKey 'PROJ' -IssueType 'Task' -Summary 'Rotate certificates' -Description 'Expires soon'
        $result.key | Should -Be 'PROJ-1'
        Should -Invoke Invoke-RestMethod -ModuleName tcs.jira -Times 1 -Exactly -ParameterFilter {
            $sent = if ($Body) { $Body | ConvertFrom-Json } else { [pscustomobject]@{} }
            $Uri -eq "$Base/rest/api/3/issue" -and $Method -eq 'Post' -and
            $sent.fields.project.key -eq 'PROJ' -and
            $sent.fields.issuetype.name -eq 'Task' -and
            $sent.fields.summary -eq 'Rotate certificates' -and
            $sent.fields.description.type -eq 'doc' -and
            $sent.fields.description.content[0].content[0].text -eq 'Expires soon' -and
            $null -eq $sent.fields.customfield_14982
        }
    }

    It 'Sends the workload type custom field only when given' {
        $null = New-JiraTicket -ProjectKey 'PROJ' -IssueType 'Task' -Summary 'S' -WorkloadType 'BAU'
        Should -Invoke Invoke-RestMethod -ModuleName tcs.jira -Times 1 -Exactly -ParameterFilter {
            $sent = if ($Body) { $Body | ConvertFrom-Json } else { [pscustomobject]@{} }
            $sent.fields.customfield_14982.value -eq 'BAU' -and $null -eq $sent.fields.description
        }
    }

    It 'Does not call Jira with -WhatIf' {
        New-JiraTicket -ProjectKey 'PROJ' -IssueType 'Task' -Summary 'S' -WhatIf
        Should -Invoke Invoke-RestMethod -ModuleName tcs.jira -Times 0 -Exactly
    }

    It 'Writes nothing to the information stream or host' {
        $output = New-JiraTicket -ProjectKey 'PROJ' -IssueType 'Task' -Summary 'S' 6>&1
        @($output).Count | Should -Be 1
        $output.key | Should -Be 'PROJ-1'
    }

    It 'Requires a summary' {
        { New-JiraTicket -ProjectKey 'PROJ' -IssueType 'Task' -Summary '' } | Should -Throw
    }
}

Describe 'New-JiraTicket telemetry' {
    BeforeEach {
        Mock -ModuleName tcs.jira Invoke-RestMethod { [pscustomobject]@{ id = '1'; key = 'PROJ-1' } }
        Mock -ModuleName tcs.jira Invoke-TelemetryCollection { }
    }

    It 'Sends Start and End events and returns only the ticket' {
        $output = New-JiraTicket -ProjectKey 'PROJ' -IssueType 'Task' -Summary 'S'
        @($output).Count | Should -Be 1
        $output.key | Should -Be 'PROJ-1'
        Should -Invoke Invoke-TelemetryCollection -ModuleName tcs.jira -Times 1 -Exactly -ParameterFilter {
            $CommandName -eq 'New-JiraTicket' -and $Stage -eq 'Start'
        }
        Should -Invoke Invoke-TelemetryCollection -ModuleName tcs.jira -Times 1 -Exactly -ParameterFilter {
            $CommandName -eq 'New-JiraTicket' -and $Stage -eq 'End' -and -not $Failed
        }
    }

    It 'Sends Start and End events with -WhatIf without calling Jira' {
        New-JiraTicket -ProjectKey 'PROJ' -IssueType 'Task' -Summary 'S' -WhatIf
        Should -Invoke Invoke-RestMethod -ModuleName tcs.jira -Times 0 -Exactly
        Should -Invoke Invoke-TelemetryCollection -ModuleName tcs.jira -Times 1 -Exactly -ParameterFilter {
            $CommandName -eq 'New-JiraTicket' -and $Stage -eq 'Start'
        }
        Should -Invoke Invoke-TelemetryCollection -ModuleName tcs.jira -Times 1 -Exactly -ParameterFilter {
            $CommandName -eq 'New-JiraTicket' -and $Stage -eq 'End' -and -not $Failed
        }
    }
}
