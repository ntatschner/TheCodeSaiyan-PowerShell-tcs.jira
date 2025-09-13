using namespace System.Management.Automation

[CmdletBinding()]
param()

$Config = [PSCustomObject]@{
    Jira = [PSCustomObject]@{
        BaseUrl = 'https://rothesay.atlassian.net'
        ApiVersion = '3'
    }
}

Set-Variable -Name 'Config' -Value $Config -Scope Global -Force
