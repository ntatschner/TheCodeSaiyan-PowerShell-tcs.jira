function Set-JSMRequestTransition {
    <#
    .SYNOPSIS
        Transitions a Jira Service Management request to a new status.
    .DESCRIPTION
        Performs a customer transition through POST /rest/servicedeskapi/request/<key>/transition.
        Get the available transition ids from
        Invoke-JiraRequest -Method Get -URIPath '/servicedeskapi/request/<key>/transition'.
    .PARAMETER IssueKey
        The issue key or id of the request, for example SD-42.
    .PARAMETER TransitionId
        The id of the transition to perform.
    .EXAMPLE
        Set-JSMRequestTransition -IssueKey 'SD-42' -TransitionId '761'

        Performs transition 761 on request SD-42.
    .OUTPUTS
        None. Jira returns no content for a successful transition.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$IssueKey,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$TransitionId
    )

    $TelemetryArgs = @{
        ModuleName    = $MyInvocation.MyCommand.Module.Name
        ModuleVersion = [string]$MyInvocation.MyCommand.Module.Version
        CommandName   = $MyInvocation.MyCommand.Name
        ExecutionID   = [guid]::NewGuid().ToString()
    }
    Invoke-TelemetryCollection @TelemetryArgs -Stage Start -ClearTimer
    try {
        if (-not $PSCmdlet.ShouldProcess($IssueKey, "Perform transition $TransitionId")) {
            Invoke-TelemetryCollection @TelemetryArgs -Stage End
            return
        }

        $body = @{ id = $TransitionId } | ConvertTo-Json
        $result = Invoke-JiraRequest -Method Post -URIPath "/servicedeskapi/request/$IssueKey/transition" -Body $body
        Write-Verbose "Successfully transitioned JSM request $IssueKey."
        if ($result) {
            Invoke-TelemetryCollection @TelemetryArgs -Stage End
            return $result
        }
        Invoke-TelemetryCollection @TelemetryArgs -Stage End
    }
    catch {
        Invoke-TelemetryCollection @TelemetryArgs -Stage End -Failed $true -Exception $_
        throw
    }
}
