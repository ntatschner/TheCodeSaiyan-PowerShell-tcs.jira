BeforeAll {
    $env:TCS_CONFIG_ROOT = Join-Path -Path $TestDrive -ChildPath 'config'
    $env:TCS_SKIP_UPDATE_CHECK = '1'
    $env:TCS_TELEMETRY_OPTOUT = '1'
    $ModuleRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
    Import-Module -Name (Join-Path -Path $ModuleRoot -ChildPath 'tcs.jira.psd1') -Force
    Set-JiraContext -JiraUrl 'https://contoso.atlassian.net' -Username 'user@contoso.com' -PersonalAccessToken 'tok-SECRET-123'
}

AfterAll {
    Remove-Module -Name tcs.jira -Force -ErrorAction SilentlyContinue
}

Describe 'Get-JSMRequest' {
    It 'Gets the request from the Service Management API' {
        Mock -ModuleName tcs.jira Invoke-RestMethod { [pscustomobject]@{ issueKey = 'SD-42'; requestTypeId = '10' } }
        $result = Get-JSMRequest -IssueKey 'SD-42'
        $result.issueKey | Should -Be 'SD-42'
        Should -Invoke Invoke-RestMethod -ModuleName tcs.jira -Times 1 -Exactly -ParameterFilter {
            $Uri -eq 'https://contoso.atlassian.net/rest/servicedeskapi/request/SD-42' -and $Method -eq 'Get'
        }
    }

    It 'Warns when the response is empty' {
        Mock -ModuleName tcs.jira Invoke-RestMethod { }
        $result = Get-JSMRequest -IssueKey 'SD-42' -WarningVariable warnings -WarningAction SilentlyContinue
        $result | Should -BeNullOrEmpty
        $warnings | Should -Not -BeNullOrEmpty
    }

    It 'Propagates request errors' {
        Mock -ModuleName tcs.jira Invoke-RestMethod { throw 'Not found' }
        { Get-JSMRequest -IssueKey 'SD-404' } | Should -Throw '*SD-404*'
    }
}

Describe 'Get-JSMRequest telemetry' {
    BeforeEach {
        Mock -ModuleName tcs.jira Invoke-TelemetryCollection { }
    }

    It 'Sends Start and End events when the request succeeds' {
        Mock -ModuleName tcs.jira Invoke-RestMethod { [pscustomobject]@{ issueKey = 'SD-42' } }
        $result = Get-JSMRequest -IssueKey 'SD-42'
        @($result).Count | Should -Be 1
        Should -Invoke Invoke-TelemetryCollection -ModuleName tcs.jira -Times 1 -Exactly -ParameterFilter {
            $CommandName -eq 'Get-JSMRequest' -and $ModuleName -eq 'tcs.jira' -and $Stage -eq 'Start'
        }
        Should -Invoke Invoke-TelemetryCollection -ModuleName tcs.jira -Times 1 -Exactly -ParameterFilter {
            $CommandName -eq 'Get-JSMRequest' -and $Stage -eq 'End' -and -not $Failed
        }
    }

    It 'Sends an End event when the response is empty' {
        Mock -ModuleName tcs.jira Invoke-RestMethod { }
        $null = Get-JSMRequest -IssueKey 'SD-42' -WarningAction SilentlyContinue
        Should -Invoke Invoke-TelemetryCollection -ModuleName tcs.jira -Times 1 -Exactly -ParameterFilter {
            $CommandName -eq 'Get-JSMRequest' -and $Stage -eq 'End' -and -not $Failed
        }
    }

    It 'Sends a failed End event and rethrows when the request fails' {
        Mock -ModuleName tcs.jira Invoke-RestMethod { throw 'Not found' }
        { Get-JSMRequest -IssueKey 'SD-404' } | Should -Throw '*SD-404*'
        Should -Invoke Invoke-TelemetryCollection -ModuleName tcs.jira -Times 1 -Exactly -ParameterFilter {
            $CommandName -eq 'Get-JSMRequest' -and $Stage -eq 'End' -and $Failed -eq $true -and $null -ne $Exception
        }
        Should -Invoke Invoke-TelemetryCollection -ModuleName tcs.jira -Times 0 -Exactly -ParameterFilter {
            $CommandName -eq 'Get-JSMRequest' -and $Stage -eq 'End' -and -not $Failed
        }
    }
}
