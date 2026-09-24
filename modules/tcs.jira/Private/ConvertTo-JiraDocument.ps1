function ConvertTo-JiraDocument {
    <#
    .SYNOPSIS
        Wraps plain text in an Atlassian Document Format (ADF) document.
    .DESCRIPTION
        Jira REST API v3 expects rich text fields (description, comment body) as ADF. The text is
        sent as a single paragraph.
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Text
    )

    @{
        type    = 'doc'
        version = 1
        content = @(
            @{
                type    = 'paragraph'
                content = @(
                    @{
                        type = 'text'
                        text = $Text
                    }
                )
            }
        )
    }
}
