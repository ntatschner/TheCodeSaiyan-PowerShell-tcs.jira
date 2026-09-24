function Update-JiraTicket {
    <#
    .SYNOPSIS
        Updates a Jira Cloud issue: transitions it, changes fields and/or adds a comment.
    .DESCRIPTION
        Performs the requested changes in this order, each as a separate REST call:
        1. -MarkDone / -MarkResolved: moves the issue to the 'Done' or 'Resolved' status, like
           Invoke-JiraIssueTransition -Status Done (or Resolved). The transition is chosen by its
           target status first, then by its exact name.
        2. -Summary / -OptionalFields: PUT /rest/api/3/issue/<key> with the fields.
        3. -Comment: POST /rest/api/3/issue/<key>/comment (the text is sent as an ADF paragraph).

        A failed transition (including when no transition leads to the status) or field update
        writes a non-terminating error and the remaining changes are still attempted; use
        -ErrorAction Stop to stop on the first failure. A failed comment is a terminating error
        (the original error from Invoke-JiraRequest). Supports -WhatIf and -Confirm.

        Issue keys can be piped in, for example from Find-JiraIssue (any object with an IssueKey
        or Key property).
    .PARAMETER IssueKey
        The issue key or id, for example PROJ-123. Accepts pipeline input by property name
        (IssueKey or Key).
    .PARAMETER Summary
        A new summary for the issue.
    .PARAMETER Comment
        A plain-text comment to add to the issue.
    .PARAMETER OptionalFields
        A hashtable of other fields to set, keyed by field id, for example @{ labels = @('ops') }.
    .PARAMETER MarkDone
        Transitions the issue to the Done status.
    .PARAMETER MarkResolved
        Transitions the issue to the Resolved status.
    .EXAMPLE
        Update-JiraTicket -IssueKey 'PROJ-123' -Comment 'Deployed to production' -MarkDone

        Transitions the issue to Done and adds a comment.
    .EXAMPLE
        Update-JiraTicket -IssueKey 'PROJ-123' -Summary 'New title' -OptionalFields @{ labels = @('ops', 'urgent') }

        Changes the summary and labels.
    .EXAMPLE
        Find-JiraIssue -JQL 'project = PROJ AND labels = stale' | Update-JiraTicket -Comment 'Closing stale issue' -MarkDone

        Comments on and closes every issue that the query returns.
    .OUTPUTS
        None.
    #>
    [CmdletBinding(DefaultParameterSetName = 'Default', SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Default')]
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'MarkDone')]
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'MarkResolved')]
        [Alias('Key')]
        [ValidatePattern('^([A-Za-z][A-Za-z0-9_]*-\d+|\d+)$')]
        [string]$IssueKey,

        [Parameter(ParameterSetName = 'Default', HelpMessage = 'A new summary for the ticket.')]
        [Parameter(ParameterSetName = 'MarkDone', HelpMessage = 'A new summary for the ticket.')]
        [Parameter(ParameterSetName = 'MarkResolved', HelpMessage = 'A new summary for the ticket.')]
        [string]$Summary,

        [Parameter(ParameterSetName = 'Default', HelpMessage = 'A new comment to add to the ticket.')]
        [Parameter(ParameterSetName = 'MarkDone', HelpMessage = 'A new comment to add to the ticket.')]
        [Parameter(ParameterSetName = 'MarkResolved', HelpMessage = 'A new comment to add to the ticket.')]
        [string]$Comment,

        [Parameter(ParameterSetName = 'Default', HelpMessage = 'A hashtable of other fields to update.')]
        [Parameter(ParameterSetName = 'MarkDone', HelpMessage = 'A hashtable of other fields to update.')]
        [Parameter(ParameterSetName = 'MarkResolved', HelpMessage = 'A hashtable of other fields to update.')]
        [hashtable]$OptionalFields,

        [Parameter(Mandatory = $true, ParameterSetName = 'MarkDone', HelpMessage = 'Mark the ticket as Done (transition to Done status)')]
        [switch]$MarkDone,

        [Parameter(Mandatory = $true, ParameterSetName = 'MarkResolved', HelpMessage = 'Mark the ticket as Resolved (transition to Resolved status)')]
        [switch]$MarkResolved
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
            if (-not $Summary -and -not $Comment -and -not $OptionalFields -and -not $MarkDone -and -not $MarkResolved) {
                throw 'You must provide at least one of -Summary, -Comment, -OptionalFields, -MarkDone or -MarkResolved to update a ticket.'
            }
            Write-Verbose "Starting Update-JiraTicket for '$IssueKey'"

            # --- Transition (Done / Resolved) ---
            $targetStatus = $null
            if ($MarkDone) { $targetStatus = 'Done' }
            if ($MarkResolved) { $targetStatus = 'Resolved' }
            if ($targetStatus -and $PSCmdlet.ShouldProcess($IssueKey, "Transition to $targetStatus")) {
                try {
                    $null = Invoke-JiraTransitionRequest -IssueKey $IssueKey -Status $targetStatus
                    Write-Verbose "Ticket $IssueKey transitioned to $targetStatus."
                }
                catch {
                    $failure = New-Object -TypeName System.InvalidOperationException -ArgumentList "Failed to transition ticket $IssueKey to $targetStatus. $($_.Exception.Message)", $_.Exception
                    Write-Error -Exception $failure -Category $_.CategoryInfo.Category -ErrorId 'JiraTransitionFailed' -TargetObject $IssueKey
                }
            }

            # --- Update fields ---
            Invoke-JiraFieldUpdate -Cmdlet $PSCmdlet -IssueKey $IssueKey -Summary $Summary -SetSummary:($PSBoundParameters.ContainsKey('Summary')) -OptionalFields $OptionalFields -Description 'ticket'

            # --- Add comment (a failure rethrows the original error) ---
            if ($PSBoundParameters.ContainsKey('Comment') -and $PSCmdlet.ShouldProcess($IssueKey, 'Add comment')) {
                $null = Add-JiraIssueComment -IssueKey $IssueKey -Text $Comment
            }

            Write-Verbose "Finished Update-JiraTicket for '$IssueKey'"
            Invoke-TelemetryCollection @TelemetryArgs -Stage End
        }
        catch {
            Invoke-TelemetryCollection @TelemetryArgs -Stage End -Failed $true -Exception $_
            throw
        }
    }
}
