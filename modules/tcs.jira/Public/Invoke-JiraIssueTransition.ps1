function Invoke-JiraIssueTransition {
    <#
    .SYNOPSIS
        Moves a Jira Cloud issue to a status, optionally with a comment.
    .DESCRIPTION
        Gets the issue's transitions (GET /rest/api/3/issue/<key>/transitions) and performs the one
        that leads to -Status (POST to the same path). The transition is chosen by its target
        status (to.name) first and then by its own name; both comparisons are exact and
        case-insensitive. When no transition matches, a terminating error lists the available
        transitions and their target statuses. -Comment is added afterwards
        (POST /rest/api/3/issue/<key>/comment).

        Supports -WhatIf and -Confirm. Update-JiraTicket -MarkDone and -MarkResolved use the same
        logic with the statuses Done and Resolved.
    .PARAMETER IssueKey
        The issue key or id, for example PROJ-123. Accepts pipeline input by property name
        (IssueKey or Key).
    .PARAMETER Status
        The name of the target status, for example 'In Progress' or 'Done'. A transition name is
        also accepted.
    .PARAMETER Comment
        Optional plain-text comment to add after the transition.
    .PARAMETER PassThru
        Returns the transition that was performed.
    .EXAMPLE
        Invoke-JiraIssueTransition -IssueKey 'PROJ-123' -Status 'In Progress'

        Moves the issue to In Progress.
    .EXAMPLE
        Find-JiraIssue -JQL 'project = PROJ AND status = "In Review"' | Invoke-JiraIssueTransition -Status Done -Comment 'Approved'

        Moves every issue in review to Done with a comment.
    .OUTPUTS
        None, or the transition object when -PassThru is used.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([pscustomobject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('Key')]
        [ValidatePattern('^([A-Za-z][A-Za-z0-9_]*-\d+|\d+)$')]
        [string]$IssueKey,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Status,

        [string]$Comment,

        [switch]$PassThru
    )

    process {
        $TelemetryArgs = @{
            ModuleName    = $MyInvocation.MyCommand.Module.Name
            ModuleVersion = [string]$MyInvocation.MyCommand.Module.Version
            CommandName   = $MyInvocation.MyCommand.Name
            ExecutionID   = [guid]::NewGuid().ToString()
        }
        Invoke-TelemetryCollection @TelemetryArgs -Stage Start -ClearTimer
        try {
            if (-not $PSCmdlet.ShouldProcess($IssueKey, "Transition to $Status")) {
                Invoke-TelemetryCollection @TelemetryArgs -Stage End
                return
            }
            $transition = Invoke-JiraTransitionRequest -IssueKey $IssueKey -Status $Status
            if ($PSBoundParameters.ContainsKey('Comment')) {
                $null = Add-JiraIssueComment -IssueKey $IssueKey -Text $Comment
            }
            if ($PassThru) {
                $transition
            }
            Invoke-TelemetryCollection @TelemetryArgs -Stage End
        }
        catch {
            Invoke-TelemetryCollection @TelemetryArgs -Stage End -Failed $true -Exception $_
            throw
        }
    }
}
