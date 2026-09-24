function Get-JiraContext {
    <#
    .SYNOPSIS
        Gets the Jira connection context of the current session, without secrets.
    .DESCRIPTION
        Returns the site URL and user name set by Set-JiraContext. The API token is never
        returned. Returns nothing when no context is set.

        Use this instead of $global:JiraContext, which is deprecated.
    .EXAMPLE
        Get-JiraContext

        Shows the site and user the tcs.jira functions connect with.
    .OUTPUTS
        PSCustomObject with ConnectionURI, OriginalConnectionURL and Username, or nothing.
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
        if ($script:JiraContext) {
            [pscustomobject]@{
                PSTypeName            = 'tcs.jira.Context'
                ConnectionURI         = $script:JiraContext.ConnectionURI
                OriginalConnectionURL = $script:JiraContext.OriginalConnectionURL
                Username              = $script:JiraContext.Username
            }
        }
        else {
            Write-Verbose 'No Jira context is set. Run Set-JiraContext first.'
        }
        Invoke-TelemetryCollection @TelemetryArgs -Stage End
    }
    catch {
        Invoke-TelemetryCollection @TelemetryArgs -Stage End -Failed $true -Exception $_
        throw
    }
}
