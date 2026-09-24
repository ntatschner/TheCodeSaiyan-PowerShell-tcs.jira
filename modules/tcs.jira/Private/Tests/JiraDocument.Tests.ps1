BeforeAll {
    $env:TCS_CONFIG_ROOT = Join-Path -Path $TestDrive -ChildPath 'config'
    $env:TCS_SKIP_UPDATE_CHECK = '1'
    $env:TCS_TELEMETRY_OPTOUT = '1'
    $ModuleRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
    Import-Module -Name (Join-Path -Path $ModuleRoot -ChildPath 'tcs.jira.psd1') -Force
}

AfterAll {
    Remove-Module -Name tcs.jira -Force -ErrorAction SilentlyContinue
}

Describe 'ConvertFrom-JiraDocument' {
    It 'Returns strings unchanged and $null for $null' {
        InModuleScope tcs.jira {
            ConvertFrom-JiraDocument -Document 'plain' | Should -Be 'plain'
            ConvertFrom-JiraDocument -Document $null | Should -BeNullOrEmpty
        }
    }

    It 'Joins inline nodes and separates blocks with new lines' {
        InModuleScope tcs.jira {
            $json = '{"type":"doc","version":1,"content":[' +
            '{"type":"heading","attrs":{"level":1},"content":[{"type":"text","text":"Title"}]},' +
            '{"type":"paragraph","content":[{"type":"text","text":"Hi "},{"type":"mention","attrs":{"id":"1","text":"@Ann"}},{"type":"hardBreak"},{"type":"text","text":"bye"},{"type":"emoji","attrs":{"shortName":":smile:"}}]},' +
            '{"type":"bulletList","content":[{"type":"listItem","content":[{"type":"paragraph","content":[{"type":"text","text":"one"}]}]},{"type":"listItem","content":[{"type":"paragraph","content":[{"type":"text","text":"two"}]}]}]}' +
            ']}'
            $document = $json | ConvertFrom-Json
            ConvertFrom-JiraDocument -Document $document | Should -Be "Title`nHi @Ann`nbye:smile:`none`ntwo"
        }
    }
}

Describe 'ConvertTo-JiraDocument' {
    It 'Wraps text in a single ADF paragraph' {
        InModuleScope tcs.jira {
            $document = ConvertTo-JiraDocument -Text 'Hello'
            $document.type | Should -Be 'doc'
            $document.version | Should -Be 1
            $document.content[0].type | Should -Be 'paragraph'
            $document.content[0].content[0].text | Should -Be 'Hello'
            ConvertFrom-JiraDocument -Document (($document | ConvertTo-Json -Depth 10) | ConvertFrom-Json) | Should -Be 'Hello'
        }
    }
}

Describe 'Select-JiraTransition' {
    It 'Matches the target status before the transition name' {
        InModuleScope tcs.jira {
            $list = @(
                [pscustomobject]@{ id = '1'; name = 'Done'; to = [pscustomobject]@{ name = 'Closed' } },
                [pscustomobject]@{ id = '2'; name = 'Finish'; to = [pscustomobject]@{ name = 'done' } }
            )
            (Select-JiraTransition -Transition $list -Name 'Done').id | Should -Be '2'
        }
    }

    It 'Never picks "Not Done" for Done (ambiguous names)' {
        InModuleScope tcs.jira {
            $list = @(
                [pscustomobject]@{ id = '1'; name = 'Not Done'; to = [pscustomobject]@{ name = "Won't Do" } },
                [pscustomobject]@{ id = '2'; name = 'Complete'; to = [pscustomobject]@{ name = 'Done' } }
            )
            (Select-JiraTransition -Transition $list -Name 'Done').id | Should -Be '2'
            Select-JiraTransition -Transition @($list[0]) -Name 'Done' | Should -BeNullOrEmpty
        }
    }

    It 'Finds "Resolve Issue" for Resolved through its target status' {
        InModuleScope tcs.jira {
            $list = @(
                [pscustomobject]@{ id = '5'; name = 'Start Progress'; to = [pscustomobject]@{ name = 'In Progress' } },
                [pscustomobject]@{ id = '9'; name = 'Resolve Issue'; to = [pscustomobject]@{ name = 'Resolved' } }
            )
            (Select-JiraTransition -Transition $list -Name 'Resolved').id | Should -Be '9'
        }
    }

    It 'Falls back to an exact transition name (Service Management transitions have no target)' {
        InModuleScope tcs.jira {
            $list = @([pscustomobject]@{ id = '5'; name = 'Cancel request' }, [pscustomobject]@{ id = '761'; name = 'done' })
            (Select-JiraTransition -Transition $list -Name 'Done').id | Should -Be '761'
        }
    }

    It 'Does no partial or whole-word matching' {
        InModuleScope tcs.jira {
            $list = @(
                [pscustomobject]@{ id = '1'; name = 'Undone'; to = [pscustomobject]@{ name = 'Open' } },
                [pscustomobject]@{ id = '2'; name = 'Mark as Done'; to = [pscustomobject]@{ name = 'Closed' } }
            )
            Select-JiraTransition -Transition $list -Name 'Done' | Should -BeNullOrEmpty
        }
    }

    It 'Returns nothing when no transition matches or the list is empty' {
        InModuleScope tcs.jira {
            Select-JiraTransition -Transition @([pscustomobject]@{ id = '1'; name = 'Start' }) -Name 'Done' | Should -BeNullOrEmpty
            Select-JiraTransition -Transition $null -Name 'Done' | Should -BeNullOrEmpty
        }
    }
}
