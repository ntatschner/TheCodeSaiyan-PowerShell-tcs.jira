function Get-JSMRequest {
    <#
    .SYNOPSIS
        Gets a Jira Service Management customer request.
    .DESCRIPTION
        Gets the request from /rest/servicedeskapi/request/<key> and returns the response as Jira
        sends it.
    .PARAMETER IssueKey
        The issue key or id of the request, for example SD-42.
    .EXAMPLE
        Get-JSMRequest -IssueKey 'SD-42'

        Gets request SD-42.
    .OUTPUTS
        PSCustomObject
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidatePattern('^([A-Za-z][A-Za-z0-9_]*-\d+|\d+)$')]
        [string]$IssueKey
    )

    $TelemetryArgs = @{
        ModuleName    = $MyInvocation.MyCommand.Module.Name
        ModuleVersion = [string]$MyInvocation.MyCommand.Module.Version
        CommandName   = $MyInvocation.MyCommand.Name
        ExecutionID   = [guid]::NewGuid().ToString()
    }
    Invoke-TelemetryCollection @TelemetryArgs -Stage Start -ClearTimer
    try {
        $response = Invoke-JiraRequest -Method Get -URIPath "/servicedeskapi/request/$([System.Uri]::EscapeDataString($IssueKey))"
        if ($response) {
            Write-Verbose "Successfully retrieved JSM request: $IssueKey."
            Invoke-TelemetryCollection @TelemetryArgs -Stage End
            return $response
        }
        Write-Warning "Failed to retrieve JSM request: $IssueKey. The response from the server was empty or invalid."
        Invoke-TelemetryCollection @TelemetryArgs -Stage End
    }
    catch {
        Invoke-TelemetryCollection @TelemetryArgs -Stage End -Failed $true -Exception $_
        throw
    }
}
