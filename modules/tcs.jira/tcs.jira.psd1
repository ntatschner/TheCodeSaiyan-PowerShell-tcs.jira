@{
    ModuleVersion        = '0.2.0'
    GUID                 = 'dd02af82-ea25-4294-b76e-e072e4d992e9'
    Author               = 'Nigel Tatschner'
    CompanyName          = 'TheCodeSaiyan'
    Copyright            = '(c) 2025-2026 Nigel Tatschner. All rights reserved.'
    Description          = 'Jira Cloud and Jira Service Management REST API client: connection context, generic requests, and functions to get, create and update issues and service requests.'
    CompatiblePSEditions = @('Desktop', 'Core')
    PowerShellVersion    = '5.1'
    RootModule           = 'tcs.jira.psm1'
    RequiredModules      = @(
        @{ ModuleName = 'tcs.core'; ModuleVersion = '0.3.0' }
    )
    FunctionsToExport    = @(
        'Clear-JiraContext',
        'Find-JiraIssue',
        'Get-JiraContext',
        'Get-JiraIssueTransition',
        'Get-JiraTicket',
        'Get-JSMRequest',
        'Get-JSMRequestTransition',
        'Get-JSMRequestType',
        'Get-JSMServiceDesk',
        'Invoke-JiraIssueTransition',
        'Invoke-JiraRequest',
        'New-JiraTicket',
        'New-JSMRequest',
        'Set-JiraContext',
        'Set-JSMRequestTransition',
        'Test-JiraContext',
        'Update-JiraTicket',
        'Update-JSMRequest'
    )
    CmdletsToExport      = @()
    VariablesToExport    = @()
    AliasesToExport      = @()
    PrivateData          = @{
        PSData = @{
            Tags         = @('Jira', 'JiraCloud', 'JSM', 'JiraServiceManagement', 'Atlassian', 'REST', 'API', 'PSEdition_Desktop', 'PSEdition_Core', 'Windows', 'Linux', 'MacOS')
            ProjectUri   = 'https://github.com/ntatschner/TheCodeSaiyan-PowerShell-tcs.jira'
            LicenseUri   = 'https://github.com/ntatschner/TheCodeSaiyan-PowerShell-tcs.jira/blob/main/LICENSE'
            ReleaseNotes = 'https://github.com/ntatschner/TheCodeSaiyan-PowerShell-tcs.jira/blob/main/CHANGELOG.md'
        }
    }
}
