function Test-JiraContext {
    <#
    .SYNOPSIS
        Checks that the Jira context works by getting the signed-in user.
    .DESCRIPTION
        Sends GET /rest/api/3/myself with the context set by Set-JiraContext and returns the user
        (accountId, displayName, emailAddress, active, timeZone ...). Throws a terminating error
        when no context is set or the request fails, for example because the API token is wrong
        (HTTP 401) or the site URL is not a Jira site.
    .EXAMPLE
        Set-JiraContext -JiraUrl 'https://contoso.atlassian.net' -Credential (Get-Credential)
        Test-JiraContext | Select-Object displayName, emailAddress

        Checks the connection and shows who is signed in.
    .OUTPUTS
        PSCustomObject. The user returned by /rest/api/3/myself.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param ()

    $TelemetryArgs = @{
        ModuleName    = $MyInvocation.MyCommand.Module.Name
        ModuleVersion = [string]$MyInvocation.MyCommand.Module.Version
        CommandName   = $MyInvocation.MyCommand.Name
        ExecutionID   = [guid]::NewGuid().ToString()
    }
    Invoke-TelemetryCollection @TelemetryArgs -Stage Start -ClearTimer
    try {
        if (-not $script:JiraContext -or -not $script:JiraCredential) {
            throw 'Jira context is not set. Run Set-JiraContext first.'
        }
        try {
            $user = Invoke-JiraRequest -Method Get -URIPath '/myself' -ErrorAction Stop
        }
        catch {
            $message = "The Jira context for '$($script:JiraContext.ConnectionURI)' (user '$($script:JiraContext.Username)') does not work. $($_.Exception.Message)"
            $exception = New-Object -TypeName System.InvalidOperationException -ArgumentList $message, $_.Exception
            $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $exception, 'JiraContextTestFailed', ([System.Management.Automation.ErrorCategory]::AuthenticationError), $script:JiraContext.ConnectionURI
            throw $errorRecord
        }
        if (-not $user -or -not $user.accountId) {
            throw "The Jira context for '$($script:JiraContext.ConnectionURI)' returned no user from /rest/api/3/myself. Check that the URL is a Jira Cloud site."
        }
        $user
        Invoke-TelemetryCollection @TelemetryArgs -Stage End
    }
    catch {
        Invoke-TelemetryCollection @TelemetryArgs -Stage End -Failed $true -Exception $_
        throw
    }
}
