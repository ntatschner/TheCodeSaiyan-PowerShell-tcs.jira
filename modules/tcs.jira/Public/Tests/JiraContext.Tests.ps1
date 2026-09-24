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

Describe 'Test-JiraContext' {
    It 'Returns the signed-in user' {
        Mock -ModuleName tcs.jira Invoke-RestMethod { [pscustomobject]@{ accountId = 'abc'; displayName = 'User'; emailAddress = 'user@contoso.com' } }
        $user = Test-JiraContext
        $user.accountId | Should -Be 'abc'
        Should -Invoke Invoke-RestMethod -ModuleName tcs.jira -Times 1 -Exactly -ParameterFilter { $Uri -eq "$Base/rest/api/3/myself" -and $Method -eq 'Get' }
    }

    It 'Throws a clear error when the request fails' {
        Mock -ModuleName tcs.jira Invoke-RestMethod { throw 'Unauthorized' }
        $caught = $null
        try { Test-JiraContext } catch { $caught = $_ }
        $caught.FullyQualifiedErrorId | Should -BeLike 'JiraContextTestFailed*'
        $caught.Exception.Message | Should -Match 'contoso.atlassian.net'
        $caught.Exception.Message | Should -Match 'Unauthorized'
        $caught.Exception.Message | Should -Not -Match 'tok-SECRET-123'
    }

    It 'Throws when the response has no user' {
        Mock -ModuleName tcs.jira Invoke-RestMethod { '<html></html>' }
        { Test-JiraContext } | Should -Throw '*returned no user*'
    }
}

Describe 'Get-JiraContext' {
    It 'Returns the context without secrets' {
        $context = Get-JiraContext
        $context.ConnectionURI | Should -Be $Base
        $context.Username | Should -Be 'user@contoso.com'
        $context.PSObject.Properties.Name | Should -Not -Contain 'PersonalAccessToken'
        ($context | Format-List -Property * | Out-String) | Should -Not -Match 'tok-SECRET-123'
    }
}

Describe 'Clear-JiraContext' {
    It 'Does nothing with -WhatIf' {
        Clear-JiraContext -WhatIf
        (Get-JiraContext).ConnectionURI | Should -Be $Base
    }

    It 'Clears the context, the credential and the global copy' {
        Clear-JiraContext
        Get-JiraContext | Should -BeNullOrEmpty
        Get-Variable -Name JiraContext -Scope Global -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
        InModuleScope tcs.jira { $script:JiraCredential | Should -BeNullOrEmpty }
        { Test-JiraContext } | Should -Throw '*Set-JiraContext*'
        Set-JiraContext -JiraUrl $Base -Username 'user@contoso.com' -PersonalAccessToken 'tok-SECRET-123'
    }
}
