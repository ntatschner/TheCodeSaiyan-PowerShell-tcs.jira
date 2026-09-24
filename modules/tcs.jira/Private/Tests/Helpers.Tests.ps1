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

Describe 'Get-JiraRetryDelay' {
    It 'Uses Retry-After seconds from a dictionary of headers' {
        InModuleScope tcs.jira {
            Get-JiraRetryDelay -Response ([pscustomobject]@{ Headers = @{ 'Retry-After' = '12' } }) -Attempt 1 | Should -Be 12
        }
    }

    It 'Uses Retry-After from a WebHeaderCollection (Windows PowerShell)' {
        InModuleScope tcs.jira {
            $headers = New-Object -TypeName System.Net.WebHeaderCollection
            $headers.Add('Retry-After', '3')
            Get-JiraRetryDelay -Response ([pscustomobject]@{ Headers = $headers }) -Attempt 1 | Should -Be 3
        }
    }

    It 'Uses Retry-After from an HttpResponseMessage (PowerShell 7)' -Skip:($PSVersionTable.PSEdition -ne 'Core') {
        InModuleScope tcs.jira {
            $response = New-Object -TypeName System.Net.Http.HttpResponseMessage -ArgumentList ([System.Net.HttpStatusCode]::TooManyRequests)
            $response.Headers.RetryAfter = New-Object -TypeName System.Net.Http.Headers.RetryConditionHeaderValue -ArgumentList ([timespan]::FromSeconds(9))
            Get-JiraRetryDelay -Response $response -Attempt 1 | Should -Be 9
        }
    }

    It 'Understands an HTTP date' {
        InModuleScope tcs.jira {
            $date = [datetime]::UtcNow.AddSeconds(30).ToString('r', [System.Globalization.CultureInfo]::InvariantCulture)
            $delay = Get-JiraRetryDelay -Response ([pscustomobject]@{ Headers = @{ 'Retry-After' = $date } }) -Attempt 1
            $delay | Should -BeGreaterOrEqual 28
            $delay | Should -BeLessOrEqual 31
        }
    }

    It 'Caps the delay and never returns a negative value' {
        InModuleScope tcs.jira {
            Get-JiraRetryDelay -Response ([pscustomobject]@{ Headers = @{ 'Retry-After' = '86400' } }) -Attempt 1 | Should -Be 60
            Get-JiraRetryDelay -Response ([pscustomobject]@{ Headers = @{ 'Retry-After' = 'Mon, 01 Jan 2001 00:00:00 GMT' } }) -Attempt 1 | Should -Be 0
        }
    }

    It 'Doubles the delay without a Retry-After header' {
        InModuleScope tcs.jira {
            Get-JiraRetryDelay -Response $null -Attempt 1 | Should -Be 2
            Get-JiraRetryDelay -Response ([pscustomobject]@{ StatusCode = 503 }) -Attempt 2 | Should -Be 4
            Get-JiraRetryDelay -Response ([pscustomobject]@{ Headers = @{} }) -Attempt 3 | Should -Be 8
        }
    }
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
