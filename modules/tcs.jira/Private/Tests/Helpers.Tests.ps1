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

Describe 'ConvertTo-JiraDateTime' {
    It 'Parses Jira date-time strings' {
        InModuleScope tcs.jira {
            $value = ConvertTo-JiraDateTime -Value '2024-01-01T10:00:00.000+0000'
            $value | Should -BeOfType ([datetime])
            $value.ToUniversalTime() | Should -Be ([datetime]::new(2024, 1, 1, 10, 0, 0, [System.DateTimeKind]::Utc))
        }
    }

    It 'Returns $null for empty or unparseable values' {
        InModuleScope tcs.jira {
            ConvertTo-JiraDateTime -Value $null | Should -BeNullOrEmpty
            ConvertTo-JiraDateTime -Value '' | Should -BeNullOrEmpty
            ConvertTo-JiraDateTime -Value 'not a date' | Should -BeNullOrEmpty
        }
    }
}
