# Creates a new Jira Cloud ticket with the provided details.
function New-JiraTicket {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ProjectKey,
        [Parameter(Mandatory = $true)]
        [string]$IssueType,
        [Parameter(Mandatory = $true)]
        [string]$Summary,
        [string]$Description,
        [Parameter(Mandatory = $true)]
        [string]$WorkloadType
    )

    $body = @{
        fields = @{
            project = @{
                key = $ProjectKey
            }
            issuetype = @{
                name = $IssueType
            }
            summary = $Summary
            # Set the custom field value from the parameter
            customfield_14982 = @{ "value" = $WorkloadType }
        }
    }

    if ($Description) {
        $body.fields.description = @{
            type    = "doc"
            version = 1
            content = @(
                @{
                    type    = "paragraph"
                    content = @(
                        @{
                            type = "text"
                            text = $Description
                        }
                    )
                }
            )
        }
    }

    # No try/catch here. Let exceptions from Invoke-JiraRequest bubble up.
    $ticket = Invoke-JiraRequest -Method Post -Resource 'issue' -Body ($body | ConvertTo-Json -Depth 10)

    if ($ticket) {
        Write-Host "Successfully created Jira ticket: $($ticket.key)"
        return $ticket
    }
    
    # This should not be reached if an error occurs, but is here as a fallback.
    return $null
}
