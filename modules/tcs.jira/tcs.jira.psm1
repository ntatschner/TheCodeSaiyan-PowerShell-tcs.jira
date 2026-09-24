#region session state (never persisted to disk)
# The connection context (URL and user name) and the credential used to build the Authorization
# header. Both are set by Set-JiraContext and only live for the current session.
$script:JiraContext = $null
$script:JiraCredential = $null
#endregion

#region load classes, then private and public functions
$ClassFiles = @(Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Classes') -Filter '*.ps1' -Recurse -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -notlike '*.Tests.ps1' })
$Private = @(Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Private') -Filter '*.ps1' -Recurse -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -notlike '*.Tests.ps1' })
$Public = @(Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Public') -Filter '*.ps1' -Recurse -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -notlike '*.Tests.ps1' })

foreach ($File in @($ClassFiles + $Private + $Public)) {
    try {
        . $File.FullName
    }
    catch {
        Write-Error -Message "Failed to import '$($File.FullName)': $_"
    }
}
#endregion

#region module config, load telemetry and update check (never blocks import)
try {
    $CurrentConfig = Get-ModuleConfig -CommandPath $PSCommandPath -ErrorAction Stop
    Invoke-TelemetryCollection -ModuleName $CurrentConfig.ModuleName -ModuleVersion $CurrentConfig.ModuleVersion -CommandName 'Import-Module' -ExecutionID ([guid]::NewGuid().ToString()) -Stage 'Module-Load'
    if ($CurrentConfig.UpdateWarning -eq $true) {
        $null = Get-ModuleStatus -ShowMessage -ModuleName $CurrentConfig.ModuleName -ModulePath $CurrentConfig.ModulePath -CacheHours $CurrentConfig.UpdateCheckIntervalHours
    }
}
catch {
    Write-Warning "tcs.jira configuration could not be loaded; defaults will be used. $($_.Exception.Message)"
}
#endregion

#region clean up when the module is removed
$ExecutionContext.SessionState.Module.OnRemove = {
    $script:JiraCredential = $null
    $script:JiraContext = $null
    # Set-JiraContext mirrors the (secret-free) context to $global:JiraContext for older scripts
    Remove-Variable -Name 'JiraContext' -Scope Global -ErrorAction SilentlyContinue
}
#endregion

Export-ModuleMember -Function $Public.BaseName
