function New-JSMRequest {
    <#
    .SYNOPSIS
        Creates a Jira Service Management customer request.
    .DESCRIPTION
        Creates a request through POST /rest/servicedeskapi/request and returns Jira's response
        (including issueKey). The request is raised on behalf of -Reporter when it is given.
    .PARAMETER ServiceDeskId
        The id of the service desk.
    .PARAMETER RequestTypeId
        The id of the request type.
    .PARAMETER Summary
        The request summary.
    .PARAMETER Description
        Optional plain-text description.
    .PARAMETER RequestFieldValues
        Optional hashtable of other request fields, keyed by field id, for example
        @{ customfield_10010 = 'Laptop model X'; priority = @{ name = 'High' } }. The entries are
        added to 'requestFieldValues'; -Summary and -Description take precedence over entries with
        the same key. Get-JSMRequestType shows the request types of a service desk.
    .PARAMETER Reporter
        Optional e-mail address or account id of the customer the request is raised on behalf of
        (sent as raiseOnBehalfOf). When omitted the request is raised by the account in the context.
    .EXAMPLE
        New-JSMRequest -ServiceDeskId '1' -RequestTypeId '10' -Summary 'New laptop' -Reporter 'user@contoso.com'

        Raises a request on behalf of a customer.
    .EXAMPLE
        New-JSMRequest -ServiceDeskId '1' -RequestTypeId '10' -Summary 'New laptop' -RequestFieldValues @{ customfield_10010 = 'Model X' }

        Raises a request and sets a custom field of the request type.
    .OUTPUTS
        PSCustomObject
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([pscustomobject])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ServiceDeskId,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$RequestTypeId,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Summary,

        [string]$Description,

        [hashtable]$RequestFieldValues,

        [Alias('RaiseOnBehalfOf')]
        [string]$Reporter
    )

    $TelemetryArgs = @{
        ModuleName    = $MyInvocation.MyCommand.Module.Name
        ModuleVersion = [string]$MyInvocation.MyCommand.Module.Version
        CommandName   = $MyInvocation.MyCommand.Name
        ExecutionID   = [guid]::NewGuid().ToString()
    }
    Invoke-TelemetryCollection @TelemetryArgs -Stage Start -ClearTimer
    try {
        # Separate name: PowerShell variable names are case-insensitive
        $fieldValues = @{}
        if ($RequestFieldValues) {
            foreach ($key in $RequestFieldValues.Keys) {
                $fieldValues[[string]$key] = $RequestFieldValues[$key]
            }
        }
        $fieldValues['summary'] = $Summary
        if ($Description) {
            $fieldValues['description'] = $Description
        }

        $body = @{
            serviceDeskId      = $ServiceDeskId
            requestTypeId      = $RequestTypeId
            requestFieldValues = $fieldValues
        }
        if ($Reporter) {
            $body['raiseOnBehalfOf'] = $Reporter
        }

        if (-not $PSCmdlet.ShouldProcess("service desk $ServiceDeskId", "Create request '$Summary'")) {
            Invoke-TelemetryCollection @TelemetryArgs -Stage End
            return
        }

        $result = Invoke-JiraRequest -Method Post -URIPath '/servicedeskapi/request' -Body $body
        if ($result) {
            Write-Verbose "Successfully created JSM request: $($result.issueKey)"
            Invoke-TelemetryCollection @TelemetryArgs -Stage End
            return $result
        }
        Invoke-TelemetryCollection @TelemetryArgs -Stage End
    }
    catch {
        Invoke-TelemetryCollection @TelemetryArgs -Stage End -Failed $true -Exception $_
        throw
    }
}
