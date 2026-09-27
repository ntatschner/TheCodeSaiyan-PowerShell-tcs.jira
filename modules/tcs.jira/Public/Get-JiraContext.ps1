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

    $telemetry = Start-TcsTelemetry
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
    }
    catch {
        Complete-TcsTelemetry -Token $telemetry -ErrorRecord $_
        throw
    }
    finally {
        Complete-TcsTelemetry -Token $telemetry
    }
}
