function Clear-JiraContext {
    <#
    .SYNOPSIS
        Removes the Jira connection context and credential from the current session.
    .DESCRIPTION
        Clears the site URL and the API token credential set by Set-JiraContext, and removes the
        deprecated $global:JiraContext copy. Other tcs.jira functions fail until Set-JiraContext
        is run again. Supports -WhatIf and -Confirm.
    .EXAMPLE
        Clear-JiraContext

        Forgets the Jira connection.
    .OUTPUTS
        None.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([void])]
    param ()

    $TelemetryArgs = @{
        ModuleName    = $MyInvocation.MyCommand.Module.Name
        ModuleVersion = [string]$MyInvocation.MyCommand.Module.Version
        CommandName   = $MyInvocation.MyCommand.Name
        ExecutionID   = [guid]::NewGuid().ToString()
    }
    Invoke-TelemetryCollection @TelemetryArgs -Stage Start -ClearTimer
    try {
        $target = 'current session'
        if ($script:JiraContext) {
            $target = [string]$script:JiraContext.ConnectionURI
        }
        if ($PSCmdlet.ShouldProcess($target, 'Clear Jira connection context')) {
            $script:JiraCredential = $null
            $script:JiraContext = $null
            Remove-Variable -Name 'JiraContext' -Scope Global -ErrorAction SilentlyContinue
            Write-Verbose 'Jira context cleared.'
        }
        Invoke-TelemetryCollection @TelemetryArgs -Stage End
    }
    catch {
        Invoke-TelemetryCollection @TelemetryArgs -Stage End -Failed $true -Exception $_
        throw
    }
}
