BeforeAll {
    $env:TCS_CONFIG_ROOT = Join-Path -Path $TestDrive -ChildPath 'config'
    $env:TCS_SKIP_UPDATE_CHECK = '1'
    $env:TCS_TELEMETRY_OPTOUT = '1'
    $ModuleRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
    Import-Module -Name (Join-Path -Path $ModuleRoot -ChildPath 'tcs.jira.psd1') -Force

    $Token = 'tok-SECRET-123'
    $EncodedPair = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes("user@contoso.com:$Token"))
}

AfterAll {
    Remove-Module -Name tcs.jira -Force -ErrorAction SilentlyContinue
}

Describe 'Set-JiraContext' {
    It 'Normalises the site URL and strips a trailing REST API path' {
        $context = Set-JiraContext -JiraUrl 'https://contoso.atlassian.net/rest/api/3/' -Username 'user@contoso.com' -PersonalAccessToken $Token -PassThru
        $context.ConnectionURI | Should -Be 'https://contoso.atlassian.net'
        $context.OriginalConnectionURL | Should -Be 'https://contoso.atlassian.net/rest/api/3'
        $context.Username | Should -Be 'user@contoso.com'
    }

    It 'Writes nothing to the pipeline without -PassThru' {
        $output = Set-JiraContext -JiraUrl 'https://contoso.atlassian.net' -Username 'user@contoso.com' -PersonalAccessToken $Token
        $output | Should -BeNullOrEmpty
    }

    It 'Rejects a URL that is not HTTPS' {
        { Set-JiraContext -JiraUrl 'http://contoso.atlassian.net' -Username 'user@contoso.com' -PersonalAccessToken $Token } | Should -Throw
    }

    It 'Mirrors a context without secrets to $global:JiraContext' {
        Set-JiraContext -JiraUrl 'https://contoso.atlassian.net' -Username 'user@contoso.com' -PersonalAccessToken $Token
        $global:JiraContext.ConnectionURI | Should -Be 'https://contoso.atlassian.net'
        $global:JiraContext.PSObject.Properties.Name | Should -Not -Contain 'AuthorizationHeader'
        $text = $global:JiraContext | Format-List -Property * | Out-String
        $text | Should -Not -Match ([regex]::Escape($Token))
        $text | Should -Not -Match ([regex]::Escape($EncodedPair))
    }

    It 'Stores the token as a SecureString credential' {
        Set-JiraContext -JiraUrl 'https://contoso.atlassian.net' -Username 'user@contoso.com' -PersonalAccessToken $Token
        InModuleScope tcs.jira {
            $script:JiraCredential | Should -BeOfType ([System.Management.Automation.PSCredential])
            $script:JiraCredential.Password | Should -BeOfType ([System.Security.SecureString])
        }
    }

    It 'Builds the Basic header from UTF-8 bytes of email:token' {
        # Non-ASCII built from code points so the test does not depend on the file encoding
        $user = 'j{0}rg@contoso.com' -f [char]0x00F6
        $secret = 't{0}k{1}n' -f [char]0x00F6, [char]0x20AC
        Set-JiraContext -JiraUrl 'https://contoso.atlassian.net' -Username $user -PersonalAccessToken $secret
        $expected = 'Basic ' + [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes("${user}:$secret"))
        $expected | Should -Be 'Basic asO2cmdAY29udG9zby5jb206dMO2a+KCrG4='
        InModuleScope tcs.jira -Parameters @{ Expected = $expected } {
            param($Expected)
            Get-JiraAuthorizationHeader | Should -BeExactly $Expected
        }
    }

    It 'Accepts a PSCredential' {
        $secure = New-Object -TypeName System.Security.SecureString
        foreach ($c in $Token.ToCharArray()) { $secure.AppendChar($c) }
        $credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList 'user@contoso.com', $secure
        Set-JiraContext -JiraUrl 'https://contoso.atlassian.net' -Credential $credential
        InModuleScope tcs.jira -Parameters @{ Expected = "Basic $EncodedPair" } {
            param($Expected)
            Get-JiraAuthorizationHeader | Should -BeExactly $Expected
        }
    }

    It 'Does not write the token to the verbose stream' {
        $verbose = Set-JiraContext -JiraUrl 'https://contoso.atlassian.net' -Username 'user@contoso.com' -PersonalAccessToken $Token -Verbose 4>&1 | Out-String
        $verbose | Should -Not -BeNullOrEmpty
        $verbose | Should -Not -Match ([regex]::Escape($Token))
        $verbose | Should -Not -Match ([regex]::Escape($EncodedPair))
    }

    It 'Does not change the context with -WhatIf' {
        Set-JiraContext -JiraUrl 'https://contoso.atlassian.net' -Username 'user@contoso.com' -PersonalAccessToken $Token
        Set-JiraContext -JiraUrl 'https://other.atlassian.net' -Username 'other@contoso.com' -PersonalAccessToken 'x' -WhatIf
        InModuleScope tcs.jira {
            $script:JiraContext.ConnectionURI | Should -Be 'https://contoso.atlassian.net'
            $script:JiraCredential.UserName | Should -Be 'user@contoso.com'
        }
    }
}
