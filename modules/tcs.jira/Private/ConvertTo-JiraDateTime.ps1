function ConvertTo-JiraDateTime {
    <#
    .SYNOPSIS
        Converts a Jira date-time string to a [datetime].
    .DESCRIPTION
        Jira sends dates such as '2024-01-01T10:00:00.000+0000'. The value is parsed with the
        invariant culture and returned as local time. $null, an empty string or a value that cannot
        be parsed returns $null; a [datetime] is returned unchanged.
    #>
    [CmdletBinding()]
    [OutputType([datetime])]
    param (
        [Parameter()]
        [AllowNull()]
        [object]$Value
    )

    if ($null -eq $Value) { return $null }
    if ($Value -is [datetime]) { return $Value }
    $text = [string]$Value
    if ([string]::IsNullOrWhiteSpace($text)) { return $null }
    try {
        [datetime]$text
    }
    catch {
        Write-Verbose "Could not parse '$text' as a date: $($_.Exception.Message)"
        $null
    }
}
