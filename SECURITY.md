# Security Policy

## Supported versions

Only the latest released version of tcs.jira receives security fixes.

## Reporting a vulnerability

Please **do not** open a public issue for security problems.

Report them privately through
[GitHub security advisories](https://github.com/ntatschner/TheCodeSaiyan-PowerShell-tcs.jira/security/advisories/new).
Include the affected version, the steps to reproduce and the impact you expect.

You should get a first response within 7 days.

## Scope notes

- `Set-JiraContext` keeps the Atlassian API token in memory for the current session only, as a
  `SecureString` inside a `PSCredential`. It is never written to disk, to the context object,
  to verbose output or to error messages. Report anything that suggests otherwise as a
  security issue.
- On Linux and macOS .NET does not encrypt `SecureString` in memory; it only keeps the value out
  of casual output. Treat the PowerShell session as holding the token.
- Credentials are only sent to the site given to `Set-JiraContext`; pagination links to other
  hosts are not followed.
- Telemetry (through tcs.core) never sends user names, machine names, paths, hardware
  identifiers, command arguments or error messages.
