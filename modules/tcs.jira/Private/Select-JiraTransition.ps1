function Select-JiraTransition {
    <#
    .SYNOPSIS
        Picks the transition that leads to a status from a list of Jira transitions.
    .DESCRIPTION
        Returns the first transition whose target status (to.name) equals -Name. When no target
        status matches, returns the first transition whose own name equals -Name. Both comparisons
        are exact and case-insensitive; there is no partial or whole-word matching, so 'Done' never
        selects 'Not Done' and 'Resolved' selects 'Resolve Issue' only through its target status.
        Returns nothing when no transition matches.

        Jira Service Management customer transitions have no target status, so they are matched by
        name only.
    #>
    [CmdletBinding()]
    [OutputType([object])]
    param (
        [Parameter()]
        [AllowNull()]
        [object[]]$Transition,

        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    $candidates = @($Transition | Where-Object { $null -ne $_ })
    $selected = @($candidates | Where-Object { $_.PSObject.Properties['to'] -and $null -ne $_.to -and [string]$_.to.name -eq $Name })
    if ($selected.Count -eq 0) {
        $selected = @($candidates | Where-Object { [string]$_.name -eq $Name })
    }
    if ($selected.Count -gt 0) {
        return $selected[0]
    }
}
