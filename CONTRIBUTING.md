# Contributing to tcs.jira

tcs.jira is part of the tcs PowerShell suite and depends on
[tcs.core](https://github.com/ntatschner/TheCodeSaiyan-PowerShell-tcs.core) 0.3.0 or later.

## Getting started

Requirements: PowerShell 7.2+ for development, Pester 5.7.1, PSScriptAnalyzer 1.23.0 and
tcs.core 0.3.0+ on `PSModulePath`.

```powershell
Install-Module Pester -RequiredVersion 5.7.1 -Scope CurrentUser -SkipPublisherCheck
Install-Module PSScriptAnalyzer -RequiredVersion 1.23.0 -Scope CurrentUser
Install-Module tcs.core -MinimumVersion 0.3.0 -Scope CurrentUser

# Tests (offline: every REST call is mocked)
Import-Module Pester -RequiredVersion 5.7.1
Invoke-Pester -Path ./modules/tcs.jira, ./tests -Output Detailed

# Lint as CI does (warnings fail the build)
Invoke-ScriptAnalyzer -Path ./modules/tcs.jira -Recurse -Settings ./PSScriptAnalyzerSettings.psd1 |
    Where-Object { $_.ScriptName -notlike '*.Tests.ps1' }
```

## Layout

| Path | Contents |
| --- | --- |
| `modules/tcs.jira/Public/` | Exported functions, one per file, named after the function |
| `modules/tcs.jira/Private/` | Internal helpers (not exported) |
| `modules/tcs.jira/Public/Tests/`, `Private/Tests/` | Pester tests, `<Function>.Tests.ps1` |
| `tests/` | Module-wide tests (manifest, exports, help, PSScriptAnalyzer) |

Every file in `Public/` must also be listed in `FunctionsToExport` in `tcs.jira.psd1`;
`tests/Module.Tests.ps1` checks this.

## Standards

- **Compatibility:** code must run on Windows PowerShell 5.1 and PowerShell 7 on Windows,
  Linux and macOS. Avoid PS7-only syntax (`??`, `?:`, `&&`, `||`, `ForEach-Object -Parallel`)
  and .NET Core-only APIs. CI runs the tests on all four.
- **Style:** 4-space indentation, `CmdletBinding()` on every function, approved verbs,
  full command names (no aliases). PSScriptAnalyzer runs with `PSScriptAnalyzerSettings.psd1`
  and **warnings fail the build**. Suppress a rule only with a written justification.
- **State-changing functions** (`New-`, `Set-`, `Update-` ...) support `-WhatIf`/`-Confirm`.
- **Secrets:** never write tokens to disk, output, verbose or error messages. Build the
  Authorization header with the private `Get-JiraAuthorizationHeader` helper.
- **Help:** every exported function has comment-based help with a synopsis, description,
  every parameter and at least one example.
- **Tests:** new behaviour and bug fixes come with Pester tests. Tests must not touch the real
  user profile or network: set `TCS_CONFIG_ROOT` to `$TestDrive` and mock `Invoke-RestMethod`
  with `Mock -ModuleName tcs.jira`.
- **Versioning:** [Semantic Versioning](https://semver.org). Record changes in `CHANGELOG.md`.

## Releasing

1. Update `ModuleVersion` in `modules/tcs.jira/tcs.jira.psd1` and `CHANGELOG.md`.
2. Open a pull request and merge it to `main` once CI passes.
