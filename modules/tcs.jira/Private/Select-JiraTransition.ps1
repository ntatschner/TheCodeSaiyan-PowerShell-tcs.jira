function Select-JiraTransition {
    <#
    .SYNOPSIS
        Picks a transition by name from a list of Jira transitions.
    .DESCRIPTION
        Returns the first transition whose name equals -Name (case-insensitive). When there is no
        exact match, returns the first transition whose name contains -Name as a whole word.
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
    $selected = @($candidates | Where-Object { [string]$_.name -eq $Name })
    if ($selected.Count -eq 0) {
        $pattern = '\b{0}\b' -f [regex]::Escape($Name)
        $selected = @($candidates | Where-Object { [string]$_.name -match $pattern })
    }
    if ($selected.Count -gt 0) {
        return $selected[0]
    }
}
