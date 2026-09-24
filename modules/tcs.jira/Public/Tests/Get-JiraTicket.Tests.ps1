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

Describe 'Get-JiraTicket' {
    BeforeAll {
        $issue = [pscustomobject]@{
            key    = 'PROJ-7'
            fields = [pscustomobject]@{
                summary     = 'Broken build'
                status      = [pscustomobject]@{ name = 'In Progress' }
                assignee    = [pscustomobject]@{ displayName = 'Ann' }
                reporter    = [pscustomobject]@{ displayName = 'Bob' }
                created     = '2024-01-01T10:00:00.000+0000'
                updated     = '2024-01-02T10:00:00.000+0000'
                description = 'desc'
                comment     = [pscustomobject]@{
                    comments = @(
                        [pscustomobject]@{
                            id           = '100'
                            author       = [pscustomobject]@{ displayName = 'Ann' }
                            body         = [pscustomobject]@{
                                type    = 'doc'
                                version = 1
                                content = @(
                                    [pscustomobject]@{ type = 'paragraph'; content = @([pscustomobject]@{ type = 'text'; text = 'Hello ' }, [pscustomobject]@{ type = 'text'; text = 'world' }) },
                                    [pscustomobject]@{ type = 'paragraph'; content = @([pscustomobject]@{ type = 'text'; text = 'Second line' }) }
                                )
                            }
                            created      = '2024-01-01T11:00:00.000+0000'
                            updated      = '2024-01-01T12:00:00.000+0000'
                            updateAuthor = [pscustomobject]@{ displayName = 'Carl' }
                        }
                    )
                }
            }
        }
    }

    It 'Requests the issue and returns a formatted object' {
        Mock -ModuleName tcs.jira Invoke-RestMethod { $issue }
        $ticket = Get-JiraTicket -IssueKey 'PROJ-7'
        Should -Invoke Invoke-RestMethod -ModuleName tcs.jira -Times 1 -Exactly -ParameterFilter {
            $Uri -eq "$Base/rest/api/3/issue/PROJ-7" -and $Method -eq 'Get'
        }
        $ticket.Key | Should -Be 'PROJ-7'
        $ticket.Url | Should -Be "$Base/browse/PROJ-7"
        $ticket.Summary | Should -Be 'Broken build'
        $ticket.Status | Should -Be 'In Progress'
        $ticket.Assignee | Should -Be 'Ann'
        $ticket.Reporter | Should -Be 'Bob'
    }

    It 'Returns comments as JiraComment objects with plain-text bodies' {
        Mock -ModuleName tcs.jira Invoke-RestMethod { $issue }
        $ticket = Get-JiraTicket -IssueKey 'PROJ-7'
        @($ticket.Comments).Count | Should -Be 1
        $comment = $ticket.Comments[0]
        $comment.GetType().Name | Should -Be 'JiraComment'
        $comment.Id | Should -Be '100'
        $comment.Author | Should -Be 'Ann'
        $comment.UpdateAuthor | Should -Be 'Carl'
        $comment.Body | Should -Be "Hello world`nSecond line"
        $comment.Created | Should -BeOfType ([datetime])
        $comment.Created.ToUniversalTime() | Should -Be ([datetime]::new(2024, 1, 1, 11, 0, 0, [System.DateTimeKind]::Utc))
    }

    It 'Handles an issue without comments' {
        Mock -ModuleName tcs.jira Invoke-RestMethod { [pscustomobject]@{ key = 'PROJ-8'; fields = [pscustomobject]@{ summary = 's' } } }
        $ticket = Get-JiraTicket -IssueKey 'PROJ-8'
        $ticket.Key | Should -Be 'PROJ-8'
        @($ticket.Comments).Count | Should -Be 0
    }

    It 'Warns and returns nothing when the response is empty' {
        Mock -ModuleName tcs.jira Invoke-RestMethod { }
        $ticket = Get-JiraTicket -IssueKey 'PROJ-9' -WarningVariable warnings -WarningAction SilentlyContinue
        $ticket | Should -BeNullOrEmpty
        $warnings | Should -Not -BeNullOrEmpty
    }
}
