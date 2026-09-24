function Update-JSMRequest {
    <#
    .SYNOPSIS
        Updates a Jira Service Management request: marks it done, changes fields and/or adds a comment.
    .DESCRIPTION
        Performs the requested changes in this order, each as a separate REST call:
        1. -MarkDone: finds the 'Done' customer transition
           (GET /rest/servicedeskapi/request/<key>/transition) and performs it.
        2. -Summary / -OptionalFields: PUT /rest/api/3/issue/<key> with the fields (the Service
           Management API has no request update endpoint).
        3. -Comment: POST /rest/api/3/issue/<key>/comment (the text is sent as an ADF paragraph).

        A failed transition or field update writes a non-terminating error and the remaining
        changes are still attempted; use -ErrorAction Stop to stop on the first failure. A failed
        comment is a terminating error. Supports -WhatIf and -Confirm.
    .PARAMETER IssueKey
        The issue key of the request, for example SD-42.
    .PARAMETER Summary
        A new summary for the request.
    .PARAMETER Comment
        A plain-text comment to add to the request.
    .PARAMETER OptionalFields
        A hashtable of other fields to set, keyed by field id.
    .PARAMETER MarkDone
        Performs the request's 'Done' transition.
    .EXAMPLE
        Update-JSMRequest -IssueKey 'SD-42' -Comment 'Laptop shipped' -MarkDone

        Marks the request done and adds a comment.
    .OUTPUTS
        None.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$IssueKey,

        [string]$Summary,

        [string]$Comment,

        [hashtable]$OptionalFields,

        [switch]$MarkDone
    )

    $TelemetryArgs = @{
        ModuleName    = $MyInvocation.MyCommand.Module.Name
        ModuleVersion = [string]$MyInvocation.MyCommand.Module.Version
        CommandName   = $MyInvocation.MyCommand.Name
        ExecutionID   = [guid]::NewGuid().ToString()
    }
    Invoke-TelemetryCollection @TelemetryArgs -Stage Start -ClearTimer
    try {
        if (-not $Summary -and -not $Comment -and -not $OptionalFields -and -not $MarkDone) {
            throw 'You must provide at least one of -Summary, -Comment, -OptionalFields, or -MarkDone to update a JSM request.'
        }
        Write-Verbose "Starting Update-JSMRequest for '$IssueKey'"

        # --- Mark as Done (customer transition) ---
        if ($MarkDone -and $PSCmdlet.ShouldProcess($IssueKey, 'Transition to Done')) {
            try {
                $transitions = Invoke-JiraRequest -Method Get -URIPath "/servicedeskapi/request/$IssueKey/transition" -ErrorAction Stop
                $transition = Select-JiraTransition -Transition @($transitions.values) -Name 'Done'
                if ($transition) {
                    $body = @{ id = [string]$transition.id } | ConvertTo-Json
                    Write-Verbose "Transitioning $IssueKey to Done using transition id $($transition.id)"
                    $null = Invoke-JiraRequest -Method Post -URIPath "/servicedeskapi/request/$IssueKey/transition" -Body $body -ErrorAction Stop
                    Write-Verbose "JSM request $IssueKey transitioned to Done."
                }
                else {
                    Write-Warning "No 'Done' transition found for JSM request $IssueKey."
                }
            }
            catch {
                Write-Error -Message "Failed to transition JSM request $IssueKey to Done. $($_.Exception.Message)"
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
                Write-Error -Message "Failed to update fields for JSM request $IssueKey. $($_.Exception.Message)"
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
                throw "Failed to add comment to JSM request $IssueKey. $($_.Exception.Message)"
            }
        }

        Write-Verbose "Finished Update-JSMRequest for '$IssueKey'"
        Invoke-TelemetryCollection @TelemetryArgs -Stage End
    }
    catch {
        Invoke-TelemetryCollection @TelemetryArgs -Stage End -Failed $true -Exception $_
        throw
    }
}
