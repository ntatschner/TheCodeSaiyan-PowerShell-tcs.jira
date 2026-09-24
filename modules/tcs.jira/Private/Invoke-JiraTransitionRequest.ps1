function Invoke-JiraTransitionRequest {
    <#
    .SYNOPSIS
        Moves a Jira issue or Service Management request to a status.
    .DESCRIPTION
        Gets the available transitions, selects the one that leads to -Status with
        Select-JiraTransition and performs it. Throws a terminating error that lists the available
        transitions when none matches.

        Without -ServiceManagement the Jira platform API is used
        (/rest/api/3/issue/<key>/transitions). With -ServiceManagement the customer transitions of
        the request are used (/rest/servicedeskapi/request/<key>/transition).

        Returns the transition that was performed.
    #>
    [CmdletBinding()]
    [OutputType([object])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$IssueKey,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Status,

        [switch]$ServiceManagement
    )

    $escapedKey = [System.Uri]::EscapeDataString($IssueKey)
    if ($ServiceManagement) {
        $path = "/servicedeskapi/request/$escapedKey/transition"
        $available = @(Invoke-JiraRequest -Method Get -URIPath $path -ErrorAction Stop)
    }
    else {
        $path = "/issue/$escapedKey/transitions"
        $available = @((Invoke-JiraRequest -Method Get -URIPath $path -ErrorAction Stop).transitions)
    }

    $transition = Select-JiraTransition -Transition $available -Name $Status
    if (-not $transition) {
        $names = @($available | Where-Object { $null -ne $_ } | ForEach-Object {
                if ($_.PSObject.Properties['to'] -and $_.to -and $_.to.name) {
                    "'{0}' (to '{1}')" -f $_.name, $_.to.name
                }
                else {
                    "'{0}'" -f $_.name
                }
            })
        $list = 'none'
        if ($names.Count -gt 0) {
            $list = $names -join ', '
        }
        $message = "No transition to status '$Status' is available for $IssueKey. Available transitions: $list."
        $exception = New-Object -TypeName System.InvalidOperationException -ArgumentList $message
        $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $exception, 'JiraTransitionNotFound', ([System.Management.Automation.ErrorCategory]::ObjectNotFound), $IssueKey
        throw $errorRecord
    }

    Write-Verbose "Transitioning $IssueKey to '$Status' using transition '$($transition.name)' (id $($transition.id))"
    if ($ServiceManagement) {
        $body = @{ id = [string]$transition.id }
    }
    else {
        $body = @{ transition = @{ id = [string]$transition.id } }
    }
    $null = Invoke-JiraRequest -Method Post -URIPath $path -Body $body -ErrorAction Stop
    $transition
}
