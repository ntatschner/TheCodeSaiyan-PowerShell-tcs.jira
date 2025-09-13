function Update-JSMRequest {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$IssueKey,
        [string]$Summary,
        [string]$Comment,
        [hashtable]$OptionalFields,
        [switch]$MarkDone
    )

    if (-not $Summary -and -not $Comment -and -not $OptionalFields -and -not $MarkDone) {
        throw "You must provide at least one of -Summary, -Comment, -OptionalFields, or -MarkDone to update a JSM request."
    }
    Write-Host "--- Starting Update-JSMRequest for '$($IssueKey)' ---" -ForegroundColor Cyan

    # --- Mark as Done (Transition) ---
    if ($MarkDone) {
        Write-Host "[DEBUG] Attempting to mark JSM request as Done..." -ForegroundColor Yellow
        try {
            $transitions = Invoke-JiraRequest -Method Get -URIPath "/servicedeskapi/request/$IssueKey/transition"
            $doneTransition = $null
            if ($transitions -and $transitions.transitions) {
                $doneTransition = $transitions.transitions | Where-Object { $_.name -match 'Done' }
            }
            if ($doneTransition) {
                $transitionId = $doneTransition[0].id
                $body = @{ transition = @{ id = $transitionId } } | ConvertTo-Json
                Write-Host "[DEBUG] Transitioning $IssueKey to Done using transition id $transitionId" -ForegroundColor Gray
                Invoke-JiraRequest -Method Post -URIPath "/servicedeskapi/request/$IssueKey/transition" -Body $body
                Write-Host "[SUCCESS] JSM request $IssueKey transitioned to Done." -ForegroundColor Green
            } else {
                Write-Warning "No 'Done' transition found for JSM request $IssueKey."
            }
        } catch {
            Write-Warning "Failed to transition JSM request $IssueKey to Done. Reason: $_"
        }
    }

    # --- Update Request Fields ---
    Write-Host "[DEBUG] Checking if fields need updating..." -ForegroundColor Gray
    if ($PSBoundParameters.ContainsKey('Summary') -or $PSBoundParameters.ContainsKey('OptionalFields')) {
        Write-Host "[DEBUG] Attempting to update JSM request fields..." -ForegroundColor Yellow
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
                Invoke-JiraRequest -Method Put -URIPath "/servicedeskapi/request/$IssueKey" -Body $jsonUpdateBody
                Write-Host "[SUCCESS] Field update request for $IssueKey completed." -ForegroundColor Green
            }
        } catch {
            Write-Warning "Failed to update fields for JSM request $IssueKey. Reason: $_"
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
            Invoke-JiraRequest -Method Post -URIPath "/rest/api/3/issue/$IssueKey/comment" -Body $jsonCommentBody
            Write-Host "[SUCCESS] Add comment request for $IssueKey completed." -ForegroundColor Green
        } catch {
            throw "Failed to add comment to JSM request $IssueKey. Reason: $_"
        }
    } else {
        Write-Host "[DEBUG] No comment to add." -ForegroundColor Gray
    }

    Write-Host "--- Finished Update-JSMRequest for '$($IssueKey)' ---" -ForegroundColor Cyan
}
