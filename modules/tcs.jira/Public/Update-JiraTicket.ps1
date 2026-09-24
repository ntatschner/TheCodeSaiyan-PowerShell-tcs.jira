function Update-JiraTicket {
    <#
    .SYNOPSIS
        Updates a Jira Cloud issue: transitions it, changes fields and/or adds a comment.
    .DESCRIPTION
        Performs the requested changes in this order, each as a separate REST call:
        1. -MarkDone / -MarkResolved: finds the 'Done' or 'Resolved' transition
           (GET /rest/api/3/issue/<key>/transitions) and performs it.
        2. -Summary / -OptionalFields: PUT /rest/api/3/issue/<key> with the fields.
        3. -Comment: POST /rest/api/3/issue/<key>/comment (the text is sent as an ADF paragraph).

        A failed transition or field update writes a non-terminating error and the remaining
        changes are still attempted; use -ErrorAction Stop to stop on the first failure. A failed
        comment is a terminating error. Supports -WhatIf and -Confirm.
    .PARAMETER IssueKey
        The issue key, for example PROJ-123.
    .PARAMETER Summary
        A new summary for the issue.
    .PARAMETER Comment
        A plain-text comment to add to the issue.
    .PARAMETER OptionalFields
        A hashtable of other fields to set, keyed by field id, for example @{ labels = @('ops') }.
    .PARAMETER MarkDone
        Transitions the issue to Done.
    .PARAMETER MarkResolved
        Transitions the issue to Resolved.
    .EXAMPLE
        Update-JiraTicket -IssueKey 'PROJ-123' -Comment 'Deployed to production' -MarkDone

        Transitions the issue to Done and adds a comment.
    .EXAMPLE
        Update-JiraTicket -IssueKey 'PROJ-123' -Summary 'New title' -OptionalFields @{ labels = @('ops', 'urgent') }

        Changes the summary and labels.
    .OUTPUTS
        None.
    #>
    [CmdletBinding(DefaultParameterSetName = 'Default', SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = 'Default')]
        [Parameter(Mandatory = $true, ParameterSetName = 'MarkDone')]
        [Parameter(Mandatory = $true, ParameterSetName = 'MarkResolved')]
        [ValidateNotNullOrEmpty()]
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
                $transitions = Invoke-JiraRequest -Method Get -Resource 'issue' -Id "$IssueKey/transitions" -ErrorAction Stop
                $transition = Select-JiraTransition -Transition @($transitions.transitions) -Name $targetStatus
                if ($transition) {
                    $body = @{ transition = @{ id = [string]$transition.id } } | ConvertTo-Json
                    Write-Verbose "Transitioning $IssueKey to $targetStatus using transition id $($transition.id)"
                    $null = Invoke-JiraRequest -Method Post -Resource 'issue' -Id "$IssueKey/transitions" -Body $body -ErrorAction Stop
                    Write-Verbose "Ticket $IssueKey transitioned to $targetStatus."
                }
                else {
                    Write-Warning "No '$targetStatus' transition found for ticket $IssueKey."
                }
            }
            catch {
                Write-Error -Message "Failed to transition ticket $IssueKey to $targetStatus. $($_.Exception.Message)"
            }
        }

        # --- Update fields ---
        $fieldsToUpdate = @{}
        if ($PSBoundParameters.ContainsKey('Summary')) {
            $fieldsToUpdate['summary'] = $Summary
        }
        if ($OptionalFields) {
            foreach ($key in $OptionalFields.Keys) {
                $fieldsToUpdate[$key] = $OptionalFields[$key]
            }
        }
        if ($fieldsToUpdate.Count -gt 0 -and $PSCmdlet.ShouldProcess($IssueKey, "Update fields: $(@($fieldsToUpdate.Keys) -join ', ')")) {
            try {
                $jsonUpdateBody = @{ fields = $fieldsToUpdate } | ConvertTo-Json -Depth 10
                $null = Invoke-JiraRequest -Method Put -Resource 'issue' -Id $IssueKey -Body $jsonUpdateBody -ErrorAction Stop
                Write-Verbose "Field update request for $IssueKey completed."
            }
            catch {
                Write-Error -Message "Failed to update fields for ticket $IssueKey. $($_.Exception.Message)"
            }
        }

        # --- Add comment ---
        if ($PSBoundParameters.ContainsKey('Comment') -and $PSCmdlet.ShouldProcess($IssueKey, 'Add comment')) {
            try {
                $jsonCommentBody = @{ body = (ConvertTo-JiraDocument -Text $Comment) } | ConvertTo-Json -Depth 10
                $null = Invoke-JiraRequest -Method Post -Resource 'issue' -Id "$IssueKey/comment" -Body $jsonCommentBody -ErrorAction Stop
                Write-Verbose "Comment added to $IssueKey."
            }
            catch {
                throw "Failed to add comment to ticket $IssueKey. $($_.Exception.Message)"
            }
        }

        Write-Verbose "Finished Update-JiraTicket for '$IssueKey'"
        Invoke-TelemetryCollection @TelemetryArgs -Stage End
    }
    catch {
        Invoke-TelemetryCollection @TelemetryArgs -Stage End -Failed $true -Exception $_
        throw
    }
}
