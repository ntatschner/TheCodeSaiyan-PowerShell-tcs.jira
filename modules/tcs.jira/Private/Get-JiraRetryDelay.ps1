function Get-JiraRetryDelay {
    <#
    .SYNOPSIS
        Returns the number of seconds to wait before retrying a failed Jira request.
    .DESCRIPTION
        Uses the Retry-After header of the HTTP response when there is one (delta seconds or an
        HTTP date). Otherwise the delay doubles with each attempt: 2, 4, 8 ... seconds. The result
        is between 0 and -MaximumSeconds.

        Works with the response objects of PowerShell 7 (HttpResponseMessage, whose headers have a
        RetryAfter property), Windows PowerShell (HttpWebResponse with a WebHeaderCollection) and
        any object whose Headers property is a dictionary.
    #>
    [CmdletBinding()]
    [OutputType([int])]
    param (
        [Parameter()]
        [AllowNull()]
        [object]$Response,

        [Parameter(Mandatory = $true)]
        [ValidateRange(1, 100)]
        [int]$Attempt,

        [ValidateRange(1, 3600)]
        [int]$MaximumSeconds = 60
    )

    $seconds = $null
    $headers = $null
    if ($null -ne $Response -and $Response.PSObject.Properties['Headers']) {
        $headers = $Response.Headers
    }

    if ($null -ne $headers) {
        $rawValue = $null
        if ($headers -is [System.Collections.IDictionary] -or $headers -is [System.Collections.Specialized.NameValueCollection]) {
            # Hashtables and WebHeaderCollection (Windows PowerShell)
            $rawValue = $headers['Retry-After']
        }
        elseif ($headers.PSObject.Properties['RetryAfter'] -and $null -ne $headers.RetryAfter) {
            # System.Net.Http.Headers.HttpResponseHeaders (PowerShell 7)
            $retryAfter = $headers.RetryAfter
            if ($null -ne $retryAfter.Delta) {
                $seconds = [int][math]::Ceiling($retryAfter.Delta.TotalSeconds)
            }
            elseif ($null -ne $retryAfter.Date) {
                $seconds = [int][math]::Ceiling(($retryAfter.Date.UtcDateTime - [datetime]::UtcNow).TotalSeconds)
            }
        }

        if ($null -ne $rawValue) {
            $text = ([string]@($rawValue)[0]).Trim()
            $number = 0
            $date = [datetime]::MinValue
            if ([int]::TryParse($text, [ref]$number)) {
                $seconds = $number
            }
            elseif ([datetime]::TryParse($text, [System.Globalization.CultureInfo]::InvariantCulture, ([System.Globalization.DateTimeStyles]::AdjustToUniversal -bor [System.Globalization.DateTimeStyles]::AssumeUniversal), [ref]$date)) {
                $seconds = [int][math]::Ceiling(($date - [datetime]::UtcNow).TotalSeconds)
            }
        }
    }

    if ($null -eq $seconds) {
        $seconds = [int][math]::Min([math]::Pow(2, $Attempt), $MaximumSeconds)
    }
    if ($seconds -lt 0) { $seconds = 0 }
    if ($seconds -gt $MaximumSeconds) { $seconds = $MaximumSeconds }
    $seconds
}
