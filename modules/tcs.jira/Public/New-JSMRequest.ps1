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
    .PARAMETER Reporter
        Optional e-mail address or account id of the customer the request is raised on behalf of
        (sent as raiseOnBehalfOf). When omitted the request is raised by the account in the context.
    .EXAMPLE
        New-JSMRequest -ServiceDeskId '1' -RequestTypeId '10' -Summary 'New laptop' -Reporter 'user@contoso.com'

        Raises a request on behalf of a customer.
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

        [Alias('RaiseOnBehalfOf')]
        [string]$Reporter
    )

    $requestFieldValues = @{ summary = $Summary }
    if ($Description) {
        $requestFieldValues['description'] = $Description
    }

    $body = @{
        serviceDeskId      = $ServiceDeskId
        requestTypeId      = $RequestTypeId
        requestFieldValues = $requestFieldValues
    }
    if ($Reporter) {
        $body['raiseOnBehalfOf'] = $Reporter
    }

    if (-not $PSCmdlet.ShouldProcess("service desk $ServiceDeskId", "Create request '$Summary'")) {
        return
    }

    $result = Invoke-JiraRequest -Method Post -URIPath '/servicedeskapi/request' -Body ($body | ConvertTo-Json -Depth 5)
    if ($result) {
        Write-Verbose "Successfully created JSM request: $($result.issueKey)"
        return $result
    }
}
