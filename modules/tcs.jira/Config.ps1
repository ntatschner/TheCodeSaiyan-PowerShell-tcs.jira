using namespace System.Management.Automation

[CmdletBinding()]
param()

$Config = [PSCustomObject]@{
    Jira = [PSCustomObject]@{
        BaseUrl = 'https://example.atlassian.net'
        ApiVersion = '3'
    }
}

Set-Variable -Name 'Config' -Value $Config -Scope Global -Force
