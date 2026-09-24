function Invoke-JiraFieldUpdate {
    <#
    .SYNOPSIS
        Updates the fields of a Jira issue with one PUT request.
    .DESCRIPTION
        Merges -Summary (when -SetSummary is given) and -OptionalFields into one 'fields' object and
        sends PUT /rest/api/3/issue/<key>. Nothing is sent when there are no fields or when the
        calling command's ShouldProcess (-Cmdlet) declines. A failure writes a non-terminating
        error that keeps the original exception, so the caller's -ErrorAction decides whether it
        stops.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCmdlet]$Cmdlet,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$IssueKey,

        [string]$Summary,

        [switch]$SetSummary,

        [hashtable]$OptionalFields,

        [string]$Description = 'ticket'
    )

    $fieldsToUpdate = @{}
    if ($SetSummary) {
        $fieldsToUpdate['summary'] = $Summary
    }
    if ($OptionalFields) {
        foreach ($key in $OptionalFields.Keys) {
            $fieldsToUpdate[$key] = $OptionalFields[$key]
        }
    }
    if ($fieldsToUpdate.Count -eq 0) {
        return
    }
    if (-not $Cmdlet.ShouldProcess($IssueKey, "Update fields: $(@($fieldsToUpdate.Keys) -join ', ')")) {
        return
    }

    try {
        $null = Invoke-JiraRequest -Method Put -URIPath "/issue/$([System.Uri]::EscapeDataString($IssueKey))" -Body @{ fields = $fieldsToUpdate } -ErrorAction Stop
        Write-Verbose "Field update request for $IssueKey completed."
    }
    catch {
        $failure = New-Object -TypeName System.InvalidOperationException -ArgumentList "Failed to update fields for $Description $IssueKey. $($_.Exception.Message)", $_.Exception
        Write-Error -Exception $failure -Category $_.CategoryInfo.Category -ErrorId 'JiraFieldUpdateFailed' -TargetObject $IssueKey
    }
}
