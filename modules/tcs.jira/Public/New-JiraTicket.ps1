function New-JiraTicket {
    <#
    .SYNOPSIS
        Creates a Jira Cloud issue.
    .DESCRIPTION
        Creates an issue through POST /rest/api/3/issue and returns Jira's response (id, key and
        self link). The description is sent as a single Atlassian Document Format paragraph.
    .PARAMETER ProjectKey
        The key of the project, for example PROJ.
    .PARAMETER IssueType
        The issue type name, for example Task or Bug.
    .PARAMETER Summary
        The issue summary.
    .PARAMETER Description
        Optional plain-text description.
    .PARAMETER Fields
        Optional hashtable of other fields to set, keyed by field id, for example
        @{ labels = @('ops'); customfield_10010 = @{ value = 'BAU' } }. The entries are added to
        the 'fields' object of the create request and replace fields built from the other
        parameters when they use the same field id.
    .EXAMPLE
        New-JiraTicket -ProjectKey 'PROJ' -IssueType 'Task' -Summary 'Rotate certificates' -Description 'Expires next month'

        Creates a task.
    .EXAMPLE
        New-JiraTicket -ProjectKey 'OPS' -IssueType 'Task' -Summary 'Patch servers' -Fields @{ labels = @('patching'); customfield_10010 = @{ value = 'BAU' } } -WhatIf

        Shows what would be created without calling Jira.
    .OUTPUTS
        PSCustomObject
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([pscustomobject])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ProjectKey,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$IssueType,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Summary,

        [string]$Description,

        [hashtable]$Fields
    )

    $TelemetryArgs = @{
        ModuleName    = $MyInvocation.MyCommand.Module.Name
        ModuleVersion = [string]$MyInvocation.MyCommand.Module.Version
        CommandName   = $MyInvocation.MyCommand.Name
        ExecutionID   = [guid]::NewGuid().ToString()
    }
    Invoke-TelemetryCollection @TelemetryArgs -Stage Start -ClearTimer
    try {
        $body = @{
            fields = @{
                project   = @{ key = $ProjectKey }
                issuetype = @{ name = $IssueType }
                summary   = $Summary
            }
        }

        if ($Description) {
            $body.fields['description'] = ConvertTo-JiraDocument -Text $Description
        }

        if ($Fields) {
            foreach ($key in $Fields.Keys) {
                $body.fields[[string]$key] = $Fields[$key]
            }
        }

        if (-not $PSCmdlet.ShouldProcess("project $ProjectKey", "Create $IssueType '$Summary'")) {
            Invoke-TelemetryCollection @TelemetryArgs -Stage End
            return
        }

        # Errors from Invoke-JiraRequest are terminating and bubble up to the caller
        $ticket = Invoke-JiraRequest -Method Post -Resource 'issue' -Body $body
        if ($ticket) {
            Write-Verbose "Successfully created Jira ticket: $($ticket.key)"
            Invoke-TelemetryCollection @TelemetryArgs -Stage End
            return $ticket
        }
        Invoke-TelemetryCollection @TelemetryArgs -Stage End
    }
    catch {
        Invoke-TelemetryCollection @TelemetryArgs -Stage End -Failed $true -Exception $_
        throw
    }
}
