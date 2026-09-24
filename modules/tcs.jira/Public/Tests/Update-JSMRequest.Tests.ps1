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

    It 'Adds a comment without doubling the API prefix' {
        Update-JSMRequest -IssueKey 'SD-1' -Comment 'Shipped'
        Should -Invoke Invoke-RestMethod -ModuleName tcs.jira -Times 1 -Exactly -ParameterFilter {
            $Uri -eq "$Base/rest/api/3/issue/SD-1/comment" -and $Method -eq 'Post' -and
            ($Body | ConvertFrom-Json).body.content[0].content[0].text -eq 'Shipped'
        }
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
