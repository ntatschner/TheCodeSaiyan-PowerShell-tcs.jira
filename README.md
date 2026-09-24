# TheCodeSaiyan PowerShell tcs.jira Module

[![Build Status](https://img.shields.io/github/actions/workflow/status/ntatschner/TheCodeSaiyan-PowerShell-tcs.jira/ci-validate.yml?branch=main&style=flat-square&label=Build)](https://github.com/ntatschner/TheCodeSaiyan-PowerShell-tcs.jira/actions/workflows/ci-validate.yml)

A small client for the **Jira Cloud** REST API (v3) and the **Jira Service Management** REST API:
set a connection context once, then get, create and update issues and service requests, or call
any endpoint with `Invoke-JiraRequest`. Part of the TheCodeSaiyan (tcs) PowerShell suite.

## Requirements

- Windows PowerShell 5.1 or PowerShell 7.2+ on Windows, Linux or macOS
- [tcs.core](https://github.com/ntatschner/TheCodeSaiyan-PowerShell-tcs.core) **0.3.0 or later**
  (installed automatically as a required module from the PowerShell Gallery)
- A Jira Cloud site and an Atlassian account e-mail address with an
  [API token](https://id.atlassian.com/manage-profile/security/api-tokens).
  Authentication is HTTP Basic (e-mail + API token), as Jira Cloud expects; Jira Data Center
  bearer tokens are not supported.

## Installation

```powershell
# From the PowerShell Gallery
Install-Module -Name tcs.jira -Scope CurrentUser

# From source (tcs.core 0.3.0+ must already be installed)
git clone https://github.com/ntatschner/TheCodeSaiyan-PowerShell-tcs.jira.git
Import-Module ./TheCodeSaiyan-PowerShell-tcs.jira/modules/tcs.jira/tcs.jira.psd1
```

## Functions

| Function | Purpose |
| --- | --- |
| `Set-JiraContext` | Sets the site URL and credentials for the session (nothing is saved to disk) |
| `Invoke-JiraRequest` | Calls any Jira / Service Management endpoint; handles paths, JQL search, paging, retries and errors |
| `Get-JiraTicket` | Gets an issue with its comments (comment bodies as plain text) |
| `New-JiraTicket` | Creates an issue |
| `Update-JiraTicket` | Transitions an issue to Done/Resolved, updates fields and/or adds a comment |
| `Get-JSMRequest` | Gets a Service Management request |
| `New-JSMRequest` | Creates a Service Management request, optionally on behalf of a customer |
| `Update-JSMRequest` | Marks a request done, updates fields and/or adds a comment |
| `Set-JSMRequestTransition` | Performs a customer transition on a request |

`New-*`, `Update-*` and `Set-*` functions support `-WhatIf` and `-Confirm`.
Run `Get-Help <function> -Full` for all parameters and examples.

### Examples

```powershell
# Connect (prompts for the API token and keeps it in a SecureString)
Set-JiraContext -JiraUrl 'https://contoso.atlassian.net' -Credential (Get-Credential -UserName 'me@contoso.com')

# Issues
Get-JiraTicket -IssueKey 'PROJ-123'
$issue = New-JiraTicket -ProjectKey 'PROJ' -IssueType 'Task' -Summary 'Rotate certificates' -Description 'Expires next month'
Update-JiraTicket -IssueKey $issue.key -Comment 'Done in change CHG-42' -MarkDone

# JQL search (follows pages up to -MaxQueryPages, default 10)
Invoke-JiraRequest -Method Get -JQL 'project = PROJ AND statusCategory != Done' -Query @{ maxResults = 100 }

# Service Management
$request = New-JSMRequest -ServiceDeskId '1' -RequestTypeId '10' -Summary 'New laptop' -Reporter 'user@contoso.com'
Update-JSMRequest -IssueKey $request.issueKey -Comment 'Laptop shipped' -MarkDone

# Any other endpoint
Invoke-JiraRequest -Method Get -URIPath '/myself'                         # /rest/api/3/myself
Invoke-JiraRequest -Method Get -URIPath '/servicedeskapi/servicedesk'     # /rest/servicedeskapi/servicedesk
Invoke-JiraRequest -Method Get -URIPath '/rest/agile/1.0/board'           # used as given
```

### Notes

- `Get-JiraTicket` returns comments as `JiraComment` objects. The class is defined inside the
  module and loaded by dot-sourcing, so the `[JiraComment]` type literal is not available in your
  own scripts, not even with `using module tcs.jira`. Use the objects' properties instead.
- `New-JiraTicket -WorkloadType` sets the `customfield_14982` select field used on the author's
  Jira site; leave it out on other sites.
- The API token is held in memory for the current session only. `$global:JiraContext` is still
  set for older scripts, but contains only the URL and user name.

## Configuration

tcs.jira uses the tcs.core settings file for update checks and telemetry. Change it with
`Set-ModuleConfig` from tcs.core:

```powershell
Set-ModuleConfig -ModuleName tcs.jira -UpdateWarning $false   # no update warning on import
Set-ModuleConfig -ModuleName tcs.jira -Telemetry $false       # no telemetry for tcs.jira
Set-ModuleConfig -ModuleName tcs.jira -Reset                  # back to defaults
```

The update check runs at most once a day (cached). Environment variables
`TCS_SKIP_UPDATE_CHECK=1`, `TCS_TELEMETRY_OPTOUT=1` and `TCS_CONFIG_ROOT` work as described in the
tcs.core README. Nothing is written to the module folder.

## Development

See [CONTRIBUTING.md](CONTRIBUTING.md) for the coding standards and how to run the tests and
PSScriptAnalyzer. Report security issues as described in [SECURITY.md](SECURITY.md).
Changes are listed in [CHANGELOG.md](CHANGELOG.md).

## Privacy and telemetry

tcs modules send anonymous usage telemetry (through tcs.core) to help find failing commands.
Telemetry is on by default and a notice is shown the first time a module is loaded. Nothing is
sent until a telemetry endpoint is configured. tcs.jira records one event when the module is
loaded.

Each event contains: time (UTC), module and command name, module version, duration, success,
the exception **type** on failure, PowerShell version and edition, OS family, PowerShell host
name, and a random installation ID created on first use.

It **never** contains: user names, machine names, file paths, hardware serial numbers, IP-based
identifiers, command arguments, error messages, Jira site URLs, issue data or credentials.

Turn it off with `Set-ModuleConfig -ModuleName tcs.jira -Telemetry $false`, or for all tcs
modules with the environment variable `TCS_TELEMETRY_OPTOUT=1`.
