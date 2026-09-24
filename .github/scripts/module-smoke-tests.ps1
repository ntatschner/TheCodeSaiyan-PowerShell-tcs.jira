param()

$moduleName = 'tcs.jira'
$repoRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
$moduleDirectory = Join-Path -Path (Join-Path -Path $repoRoot -ChildPath 'modules') -ChildPath $moduleName
$moduleManifest = Join-Path -Path $moduleDirectory -ChildPath "$moduleName.psd1"

if (-not (Test-Path -Path $moduleManifest)) {
    throw "Module manifest not found at path: $moduleManifest"
}

# Keep the smoke test offline and away from the real user profile
$env:TCS_SKIP_UPDATE_CHECK = '1'
$env:TCS_TELEMETRY_OPTOUT = '1'
$env:TCS_CONFIG_ROOT = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath "tcs-smoke-$([guid]::NewGuid().ToString('N'))"

try {
    Write-Output "Importing $moduleName from $moduleManifest"
    $importOutput = Import-Module -Name $moduleManifest -Force -ErrorAction Stop
    if ($null -ne $importOutput) { throw 'Importing the module wrote to the pipeline.' }

    $exported = @((Get-Module $moduleName).ExportedFunctions.Keys)
    $expected = @((Import-PowerShellDataFile -Path $moduleManifest).FunctionsToExport)
    $missing = $expected | Where-Object { $_ -notin $exported }
    if ($missing -or $exported.Count -ne $expected.Count) {
        throw "Exported functions do not match the manifest. Expected $($expected.Count), got $($exported.Count): $($exported -join ', ')"
    }

    # Requests fail clearly before a context is set
    $failedWithoutContext = $false
    try { Invoke-JiraRequest -Method Get -Resource issue -Id 'SMOKE-1' } catch { $failedWithoutContext = $_.Exception.Message -like '*Set-JiraContext*' }
    if (-not $failedWithoutContext) { throw 'Invoke-JiraRequest did not report a missing Jira context.' }

    # The context never exposes the token
    $token = 'smoke-token-not-real'
    $context = Set-JiraContext -JiraUrl 'https://example.atlassian.net/rest/api/3' -Username 'smoke@example.com' -PersonalAccessToken $token -PassThru
    if ($context.ConnectionURI -ne 'https://example.atlassian.net') { throw "Set-JiraContext normalised the URL to '$($context.ConnectionURI)'." }
    if (($context | Format-List -Property * | Out-String) -match [regex]::Escape($token)) { throw 'The Jira context exposes the API token.' }

    # State-changing functions honour -WhatIf (no network call is made)
    New-JiraTicket -ProjectKey 'SMOKE' -IssueType 'Task' -Summary 'Smoke test' -WhatIf
    Update-JiraTicket -IssueKey 'SMOKE-1' -Comment 'Smoke test' -WhatIf
    Set-JSMRequestTransition -IssueKey 'SMOKE-1' -TransitionId '1' -WhatIf
    Invoke-JiraIssueTransition -IssueKey 'SMOKE-1' -Status 'Done' -WhatIf

    # The context can be read without secrets and cleared
    if ((Get-JiraContext | Format-List -Property * | Out-String) -match [regex]::Escape($token)) { throw 'Get-JiraContext exposes the API token.' }
    Clear-JiraContext
    if (Get-JiraContext) { throw 'Clear-JiraContext did not clear the context.' }

    Write-Output 'All smoke tests passed successfully.'
}
finally {
    Remove-Module -Name $moduleName -Force -ErrorAction SilentlyContinue
    Remove-Item -Path $env:TCS_CONFIG_ROOT -Recurse -Force -ErrorAction SilentlyContinue
}
