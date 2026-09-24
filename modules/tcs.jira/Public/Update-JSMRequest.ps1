function Update-JSMRequest {
    <#
    .SYNOPSIS
        Updates a Jira Service Management request: marks it done, changes fields and/or adds a comment.
    .DESCRIPTION
        Performs the requested changes in this order, each as a separate REST call:
        1. -MarkDone: performs the request's 'Done' customer transition
           (GET /rest/servicedeskapi/request/<key>/transition, exact name match).
        2. -Summary / -OptionalFields: PUT /rest/api/3/issue/<key> with the fields (the Service
           Management API has no request update endpoint).
        3. -Comment: POST /rest/servicedeskapi/request/<key>/comment. The comment is public
           (visible to the customer) unless -Internal is given.

        A failed transition (including when there is no 'Done' transition) or field update writes
        a non-terminating error and the remaining changes are still attempted; use
        -ErrorAction Stop to stop on the first failure. A failed comment is a terminating error
        (the original error from Invoke-JiraRequest). Supports -WhatIf and -Confirm.

        Issue keys can be piped in (any object with an IssueKey or Key property).
    .PARAMETER IssueKey
        The issue key or id of the request, for example SD-42. Accepts pipeline input by property
        name (IssueKey or Key).
    .PARAMETER Summary
        A new summary for the request.
    .PARAMETER Comment
        A plain-text comment to add to the request.
    .PARAMETER Internal
        Adds -Comment as an internal comment, visible to agents only.
    .PARAMETER OptionalFields
        A hashtable of other fields to set, keyed by field id.
    .PARAMETER MarkDone
        Performs the request's 'Done' transition.
    .EXAMPLE
        Update-JSMRequest -IssueKey 'SD-42' -Comment 'Laptop shipped' -MarkDone

        Marks the request done and adds a public comment.
    .EXAMPLE
        Update-JSMRequest -IssueKey 'SD-42' -Comment 'Waiting for the supplier' -Internal

        Adds an internal comment that the customer does not see.
    .OUTPUTS
        None.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('Key')]
        [ValidatePattern('^([A-Za-z][A-Za-z0-9_]*-\d+|\d+)$')]
        [string]$IssueKey,

        [string]$Summary,

        [string]$Comment,

        [switch]$Internal,

        [hashtable]$OptionalFields,

        [switch]$MarkDone
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
            if (-not $Summary -and -not $Comment -and -not $OptionalFields -and -not $MarkDone) {
                throw 'You must provide at least one of -Summary, -Comment, -OptionalFields, or -MarkDone to update a JSM request.'
            }
            Write-Verbose "Starting Update-JSMRequest for '$IssueKey'"

            # --- Mark as Done (customer transition) ---
            if ($MarkDone -and $PSCmdlet.ShouldProcess($IssueKey, 'Transition to Done')) {
                try {
                    $null = Invoke-JiraTransitionRequest -IssueKey $IssueKey -Status 'Done' -ServiceManagement
                    Write-Verbose "JSM request $IssueKey transitioned to Done."
                }
                catch {
                    $failure = New-Object -TypeName System.InvalidOperationException -ArgumentList "Failed to transition JSM request $IssueKey to Done. $($_.Exception.Message)", $_.Exception
                    Write-Error -Exception $failure -Category $_.CategoryInfo.Category -ErrorId 'JiraTransitionFailed' -TargetObject $IssueKey
                }
            }

            # --- Update fields ---
            Invoke-JiraFieldUpdate -Cmdlet $PSCmdlet -IssueKey $IssueKey -Summary $Summary -SetSummary:($PSBoundParameters.ContainsKey('Summary')) -OptionalFields $OptionalFields -Description 'JSM request'

            # --- Add comment (a failure rethrows the original error) ---
            if ($PSBoundParameters.ContainsKey('Comment')) {
                $visibility = 'public'
                if ($Internal) { $visibility = 'internal' }
                if ($PSCmdlet.ShouldProcess($IssueKey, "Add $visibility comment")) {
                    $null = Add-JiraIssueComment -IssueKey $IssueKey -Text $Comment -ServiceManagement -Public (-not $Internal)
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
}
