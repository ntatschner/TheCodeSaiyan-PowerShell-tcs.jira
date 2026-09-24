# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.1] - 2026-09-24

### Fixed
- Restored the hand-written `about_tcs.jira` help topic. The shared docs workflow had replaced it with the PlatyPS placeholder.

## [0.1.0] - 2026-09-24

### Breaking changes
- Requires tcs.core 0.3.0 or later.
- `Set-JiraContext` no longer puts the Authorization header in the context:
  `$global:JiraContext.AuthorizationHeader` is gone. The token is kept in a `PSCredential` in
  module scope and the header is built for each request. The context is still mirrored to
  `$global:JiraContext` (URL and user name only).
- `Invoke-JiraRequest -JQL` uses the enhanced search endpoint `/rest/api/3/search/jql`
  (the old `/rest/api/3/search` endpoint was retired by Atlassian) with `nextPageToken` paging,
  and requests `*navigable` fields unless `-Query` sets `fields`.
- `Invoke-JiraRequest -Method` only accepts Get, Post, Put, Delete and Patch; errors are
  terminating `ErrorRecord`s (id `JiraRequestFailed`) that keep the original exception.
- `Update-JiraTicket` / `Update-JSMRequest` write nothing to the pipeline or host (they used to
  print `[DEBUG]` host text and leak the comment response). Failed transitions and field updates
  are non-terminating errors instead of warnings.
- `New-JiraTicket -WorkloadType` and `New-JSMRequest -Reporter` are optional.
- `New-*`, `Update-*` and `Set-*` messages use `Write-Verbose` instead of `Write-Host`.
- `Config.ps1` (an unused script that set a global `$Config`) was removed.

### Added
- `-WhatIf`/`-Confirm` on `New-JiraTicket`, `Update-JiraTicket`, `New-JSMRequest`,
  `Update-JSMRequest`, `Set-JSMRequestTransition` and `Set-JiraContext`.
- `Set-JiraContext -Credential` and `-PassThru`.
- Retries for HTTP 429 as well as 503; a warning when `-MaxQueryPages` stops paging early.
- `Update-JiraTicket -MarkResolved` documented; exact transition names are preferred over
  partial matches (so "Undone" no longer matches "Done").
- Comment-based help for every function.
- Pester tests for every function with `Invoke-RestMethod` mocked (URLs, methods, headers,
  bodies, paging, retries, errors, secrets), module-wide tests and a CI smoke test.
- CI on Windows PowerShell 5.1 and PowerShell 7 on Windows, Linux and macOS, with pinned
  Pester and PSScriptAnalyzer; lint fails on warnings.
- `.editorconfig`, `.gitattributes`, `.gitignore`, `CONTRIBUTING.md`, `SECURITY.md`,
  issue/PR templates, `CODEOWNERS` and Dependabot for GitHub Actions.
- Every exported command reports an anonymous usage event through tcs.core
  `Invoke-TelemetryCollection` (Start/End, with failures reported and rethrown unchanged).
  Opt out with `$env:TCS_TELEMETRY_OPTOUT = '1'` or `Set-ModuleConfig -ModuleName tcs.jira -Telemetry $false`.
  A module test fails if an exported command does not report telemetry.
- `about_tcs.jira` help topic (`Get-Help about_tcs.jira`).
- Release workflows: `create-version-tag.yml` (tags `v<ModuleVersion>` after CI Validate on
  `main`), `generate-docs.yml` (PlatyPS help in `docs/` and `en-GB/`) and
  `publish-to-psgallery.yml`, with `.github/PUBLISHING.md` describing the release steps.
- The CI workflow is named `CI Validate` so the tag and docs workflows can run after it.

### Fixed
- Service Management requests were sent to `/servicedeskapi/...` instead of
  `/rest/servicedeskapi/...`.
- `Update-JSMRequest -Comment` called `/rest/api/3/rest/api/3/issue/...`.
- `Update-JSMRequest` field updates used a Service Management endpoint that does not exist;
  they now use `PUT /rest/api/3/issue/<key>`.
- `Update-JSMRequest -MarkDone` never found a transition (it read `transitions` instead of the
  Service Management `values`) and `Set-JSMRequestTransition` sent the wrong body
  (`{transition:{id}}` instead of `{id}`).
- `New-JSMRequest` sent an unsupported `reporter` field; it now sends `raiseOnBehalfOf`.
- `Update-JiraTicket` used `&&`, which does not parse on Windows PowerShell 5.1, so the
  function failed to load there.
- The Base64 Authorization header was visible in `$JiraContext` output.
- Request bodies were sent as ISO-8859-1 on Windows PowerShell 5.1; they are now UTF-8.
- `Invoke-JiraRequest -JQL` added `jql` to the caller's `-Query` hashtable.
- Credentials could be sent to any host named in a `nextPage` link; only the configured site is
  followed.
- `Get-JiraTicket` put the ADF object's string form (`@{type=doc; ...}`) in comment bodies.
- Module import: telemetry used a placeholder URI and the obsolete `-Minimal` switch;
  `Get-ModuleStatus` output leaked to the pipeline; paths used backslashes.
- Classes are loaded before functions; Public/Private discovery is recursive and skips tests.
- Removed the per-folder whitelist `.gitignore` that ignored test folders.
