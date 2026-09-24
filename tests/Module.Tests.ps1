BeforeDiscovery {
    $RepoRoot = Split-Path -Path $PSScriptRoot -Parent
    $ModuleRoot = Join-Path -Path $RepoRoot -ChildPath 'modules/tcs.jira'
    $PublicFunctions = @(Get-ChildItem -Path (Join-Path $ModuleRoot 'Public') -Filter '*.ps1' | ForEach-Object BaseName | ForEach-Object { @{ Name = $_ } })
    $ExportedFunctions = @((Import-PowerShellDataFile -Path (Join-Path $ModuleRoot 'tcs.jira.psd1')).FunctionsToExport | ForEach-Object { @{ Name = $_ } })
}

BeforeAll {
    $env:TCS_CONFIG_ROOT = Join-Path -Path $TestDrive -ChildPath 'config'
    $env:TCS_SKIP_UPDATE_CHECK = '1'
    $env:TCS_TELEMETRY_OPTOUT = '1'
    $RepoRoot = Split-Path -Path $PSScriptRoot -Parent
    $ModuleRoot = Join-Path -Path $RepoRoot -ChildPath 'modules/tcs.jira'
    $ManifestPath = Join-Path -Path $ModuleRoot -ChildPath 'tcs.jira.psd1'
    Import-Module -Name $ManifestPath -Force -ErrorVariable importErrors
    $Module = Get-Module -Name tcs.jira
}

AfterAll {
    Remove-Module -Name tcs.jira -Force -ErrorAction SilentlyContinue
}

Describe 'tcs.jira module' {
    It 'Has a valid manifest' {
        { Test-ModuleManifest -Path $ManifestPath -ErrorAction Stop } | Should -Not -Throw
    }

    It 'Imports without errors' {
        $importErrors.Count | Should -Be 0
    }

    It 'Exports exactly the functions in Public/ and listed in the manifest' {
        $publicFiles = Get-ChildItem -Path (Join-Path $ModuleRoot 'Public') -Filter '*.ps1' | ForEach-Object BaseName | Sort-Object
        $manifestExports = (Import-PowerShellDataFile -Path $ManifestPath).FunctionsToExport | Sort-Object
        $manifestExports | Should -Be $publicFiles
        ($Module.ExportedFunctions.Keys | Sort-Object) | Should -Be $publicFiles
    }

    It 'Does not export private helpers' {
        foreach ($helper in @('Get-JiraAuthorizationHeader', 'ConvertFrom-JiraDocument', 'ConvertTo-JiraDocument', 'Select-JiraTransition')) {
            $Module.ExportedFunctions.Keys | Should -Not -Contain $helper
        }
    }

    It 'Requires tcs.core 0.3.0 or later' {
        $required = (Import-PowerShellDataFile -Path $ManifestPath).RequiredModules | Where-Object { $_.ModuleName -eq 'tcs.core' }
        [version]$required.ModuleVersion | Should -BeGreaterOrEqual ([version]'0.3.0')
    }

    It 'Does not create files in the module folder when imported' {
        $before = @(Get-ChildItem -Path $ModuleRoot -Recurse -File | ForEach-Object FullName | Sort-Object)
        Import-Module -Name $ManifestPath -Force
        $after = @(Get-ChildItem -Path $ModuleRoot -Recurse -File | ForEach-Object FullName | Sort-Object)
        $after | Should -Be $before
    }

    It 'Does not write to the pipeline when imported' {
        $output = & (Get-Command pwsh, powershell -ErrorAction SilentlyContinue | Select-Object -First 1).Source -NoProfile -NonInteractive -Command "`$env:TCS_CONFIG_ROOT='$($env:TCS_CONFIG_ROOT)'; `$env:TCS_SKIP_UPDATE_CHECK='1'; Import-Module '$ManifestPath' 6>`$null; 'done'"
        $output | Should -Be 'done'
    }
}

Describe 'Help for <Name>' -ForEach $PublicFunctions {
    BeforeAll {
        $help = Get-Help -Name $Name -Full
    }

    It 'Has a synopsis' {
        $help.Synopsis | Should -Not -BeNullOrEmpty
        $help.Synopsis | Should -Not -Match "^\s*$Name\s"
    }

    It 'Has a description' {
        ($help.Description | Out-String).Trim() | Should -Not -BeNullOrEmpty
    }

    It 'Has at least one example' {
        @($help.Examples.Example).Count | Should -BeGreaterThan 0
    }

    It 'Documents every parameter' {
        $common = [System.Management.Automation.PSCmdlet]::CommonParameters + [System.Management.Automation.PSCmdlet]::OptionalCommonParameters
        $parameters = (Get-Command -Name $Name).Parameters.Keys | Where-Object { $_ -notin $common }
        foreach ($parameter in $parameters) {
            $parameterHelp = $help.Parameters.Parameter | Where-Object Name -EQ $parameter
            ($parameterHelp.Description | Out-String).Trim() | Should -Not -BeNullOrEmpty -Because "parameter '$parameter' should be documented"
        }
    }
}

# Coverage guard: every exported command reports telemetry through tcs.core (Start and End stages)
Describe 'Telemetry for <Name>' -ForEach $ExportedFunctions {
    BeforeAll {
        $definition = (Get-Command -Name $Name -Module tcs.jira).Definition
    }

    It 'Sends a Start event' {
        $definition | Should -Match 'Invoke-TelemetryCollection\b[^\r\n]*-Stage\s+Start'
    }

    It 'Sends an End event' {
        $definition | Should -Match 'Invoke-TelemetryCollection\b[^\r\n]*-Stage\s+End'
    }

    It 'Sends a failed End event' {
        $definition | Should -Match 'Invoke-TelemetryCollection\b[^\r\n]*-Stage\s+End\s+-Failed\s+\$true'
    }
}

Describe 'PSScriptAnalyzer' -Skip:(-not (Get-Module -ListAvailable -Name PSScriptAnalyzer)) {
    It 'Reports no findings with the repository settings' {
        $settings = Join-Path -Path $RepoRoot -ChildPath 'PSScriptAnalyzerSettings.psd1'
        # Pester files are excluded: PSScriptAnalyzer cannot follow Pester's block scoping.
        # Files are analysed one at a time and retried once, because PSScriptAnalyzer can throw an
        # intermittent internal NullReferenceException; an error that persists fails the test.
        $files = Get-ChildItem -Path $ModuleRoot -Recurse -Include '*.ps1', '*.psm1', '*.psd1' | Where-Object { $_.Name -notlike '*.Tests.ps1' }
        $findings = foreach ($file in $files) {
            try {
                Invoke-ScriptAnalyzer -Path $file.FullName -Settings $settings -ErrorAction Stop
            }
            catch {
                Invoke-ScriptAnalyzer -Path $file.FullName -Settings $settings -ErrorAction Stop
            }
        }
        $findings | ForEach-Object { Write-Host "$($_.ScriptName):$($_.Line) $($_.RuleName) $($_.Message)" }
        @($findings).Count | Should -Be 0
    }
}
