# Updates the fields of an existing Jira Cloud ticket and/or adds a comment.

function Update-JiraTicket {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = 'Default')]
        [Parameter(Mandatory = $true, ParameterSetName = 'MarkDone')]
        [Parameter(Mandatory = $true, ParameterSetName = 'MarkResolved')]
        [string]$IssueKey,

        [Parameter(Mandatory = $false, ParameterSetName = 'Default', HelpMessage = "A new summary for the ticket.")]
        [Parameter(Mandatory = $false, ParameterSetName = 'MarkDone', HelpMessage = "A new summary for the ticket.")]
        [Parameter(Mandatory = $false, ParameterSetName = 'MarkResolved', HelpMessage = "A new summary for the ticket.")]
        [string]$Summary,

        [Parameter(Mandatory = $false, ParameterSetName = 'Default', HelpMessage = "A new comment to add to the ticket.")]
        [Parameter(Mandatory = $false, ParameterSetName = 'MarkDone', HelpMessage = "A new comment to add to the ticket.")]
        [Parameter(Mandatory = $false, ParameterSetName = 'MarkResolved', HelpMessage = "A new comment to add to the ticket.")]
        [string]$Comment,

        [Parameter(Mandatory = $false, ParameterSetName = 'Default', HelpMessage = "A hashtable of other fields to update.")]
        [Parameter(Mandatory = $false, ParameterSetName = 'MarkDone', HelpMessage = "A hashtable of other fields to update.")]
        [Parameter(Mandatory = $false, ParameterSetName = 'MarkResolved', HelpMessage = "A hashtable of other fields to update.")]
        [hashtable]$OptionalFields,

        [Parameter(Mandatory = $true, ParameterSetName = 'MarkDone', HelpMessage = "Mark the ticket as Done (transition to Done status)")]
        [switch]$MarkDone,

        [Parameter(Mandatory = $true, ParameterSetName = 'MarkResolved', HelpMessage = "Mark the ticket as Resolved (transition to Resolved status)")]
        [switch]$MarkResolved
    )


    begin {
        if (-not $Summary -and -not $Comment -and -not $OptionalFields -and -not $MarkDone -and -not $MarkResolved) {
            throw "You must provide at least one of -Summary, -Comment, -OptionalFields, or -MarkDone to update a ticket."
        }
        Write-Host "--- Starting Update-JiraTicket for '$($IssueKey)' ---" -ForegroundColor Cyan
    }
    process {

        # --- Mark as Done (Transition) ---
        if ($MarkDone) {
            Write-Host "[DEBUG] Attempting to mark ticket as Done..." -ForegroundColor Yellow
            try {
                $transitions = Invoke-JiraRequest -Method Get -Resource 'issue' -Id "$IssueKey/transitions"
                $doneTransition = $null
                if ($transitions && $transitions.transitions) {
                    $doneTransition = $transitions.transitions | Where-Object { $_.name -match 'Done' }
                }
                if ($doneTransition) {
                    $transitionId = $doneTransition[0].id
                    $body = @{ transition = @{ id = $transitionId } } | ConvertTo-Json
                    Write-Host "[DEBUG] Transitioning $IssueKey to Done using transition id $transitionId" -ForegroundColor Gray
                    Invoke-JiraRequest -Method Post -Resource 'issue' -Id "$IssueKey/transitions" -Body $body
                    Write-Host "[SUCCESS] Ticket $IssueKey transitioned to Done." -ForegroundColor Green
                } else {
                    Write-Warning "No 'Done' transition found for ticket $IssueKey."
                }
            } catch {
                Write-Warning "Failed to transition ticket $IssueKey to Done. Reason: $_"
            }
        }

        # --- Mark as Resolved (Transition) ---
        if ($MarkResolved) {
            Write-Host "[DEBUG] Attempting to mark ticket as Resolved..." -ForegroundColor Yellow
            try {
                $transitions = Invoke-JiraRequest -Method Get -Resource 'issue' -Id "$IssueKey/transitions"
                $resolvedTransition = $null
                if ($transitions && $transitions.transitions) {
                    $resolvedTransition = $transitions.transitions | Where-Object { $_.name -match 'Resolved' }
                }
                if ($resolvedTransition) {
                    $transitionId = $resolvedTransition[0].id
                    $body = @{ transition = @{ id = $transitionId } } | ConvertTo-Json
                    Write-Host "[DEBUG] Transitioning $IssueKey to Resolved using transition id $transitionId" -ForegroundColor Gray
                    Invoke-JiraRequest -Method Post -Resource 'issue' -Id "$IssueKey/transitions" -Body $body
                    Write-Host "[SUCCESS] Ticket $IssueKey transitioned to Resolved." -ForegroundColor Green
                } else {
                    Write-Warning "No 'Resolved' transition found for ticket $IssueKey."
                }
            } catch {
                Write-Warning "Failed to transition ticket $IssueKey to Resolved. Reason: $_"
            }
        }

        # --- Update Ticket Fields ---
        Write-Host "[DEBUG] Checking if fields need updating..." -ForegroundColor Gray
        if ($PSBoundParameters.ContainsKey('Summary') -or $PSBoundParameters.ContainsKey('OptionalFields')) {
            Write-Host "[DEBUG] Attempting to update ticket fields..." -ForegroundColor Yellow
            try {
                $fieldsToUpdate = @{}
                if ($PSBoundParameters.ContainsKey('Summary')) {
                    $fieldsToUpdate.summary = $Summary
                    Write-Host "[DEBUG] Summary to update: '$($Summary)'" -ForegroundColor Gray
                }
                if ($PSBoundParameters.ContainsKey('OptionalFields')) {
                    foreach ($key in $OptionalFields.Keys) {
                        $fieldsToUpdate[$key] = $OptionalFields[$key]
                    }
                }

                if ($fieldsToUpdate.Count -gt 0) {
                    $updateBody = @{ fields = $fieldsToUpdate }
                    $jsonUpdateBody = $updateBody | ConvertTo-Json -Depth 10
                    Write-Host "[DEBUG] Field update request body: $jsonUpdateBody" -ForegroundColor Gray
                    Invoke-JiraRequest -Method Put -Resource 'issue' -Id $IssueKey -Body $jsonUpdateBody
                    Write-Host "[SUCCESS] Field update request for $IssueKey completed." -ForegroundColor Green
                }
            }
            catch {
                Write-Warning "Failed to update fields for ticket $IssueKey. Reason: $_"
            }
        } else {
            Write-Host "[DEBUG] No fields to update." -ForegroundColor Gray
        }

        # --- Add Comment ---
        Write-Host "[DEBUG] Checking if a comment needs to be added..." -ForegroundColor Gray
        if ($PSBoundParameters.ContainsKey('Comment')) {
            Write-Host "[DEBUG] Attempting to add comment..." -ForegroundColor Yellow
            try {
                Write-Host "[DEBUG] Comment to add: '$($Comment)'" -ForegroundColor Gray
                $commentBody = @{
                    body = @{
                        type    = "doc"
                        version = 1
                        content = @(
                            @{
                                type    = "paragraph"
                                content = @(
                                    @{
                                        type = "text"
                                        text = $Comment
                                    }
                                )
                            }
                        )
                    }
                }
                $jsonCommentBody = $commentBody | ConvertTo-Json -Depth 10
                Write-Host "[DEBUG] Comment request body: $jsonCommentBody" -ForegroundColor Gray
                Invoke-JiraRequest -Method Post -Resource 'issue' -Id "$IssueKey/comment" -Body $jsonCommentBody
                Write-Host "[SUCCESS] Add comment request for $IssueKey completed." -ForegroundColor Green
            }
            catch {
                throw "Failed to add comment to ticket $IssueKey. Reason: $_"
            }
        } else {
            Write-Host "[DEBUG] No comment to add." -ForegroundColor Gray
        }
    }

    end {
        Write-Host "--- Finished Update-JiraTicket for '$($IssueKey)' ---" -ForegroundColor Cyan
    }
}
