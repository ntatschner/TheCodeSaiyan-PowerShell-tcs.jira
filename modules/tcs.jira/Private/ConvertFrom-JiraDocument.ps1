function ConvertFrom-JiraDocument {
    <#
    .SYNOPSIS
        Converts an Atlassian Document Format (ADF) node to plain text.
    .DESCRIPTION
        Jira REST API v3 returns rich text (descriptions, comment bodies) as ADF objects. This returns
        the text content: inline nodes are joined as-is, block nodes are separated by new lines.
        Strings are returned unchanged and $null returns $null.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter()]
        [AllowNull()]
        [object]$Document
    )

    if ($null -eq $Document) { return $null }
    if ($Document -is [string]) { return $Document }

    $type = [string]$Document.type
    if ($type -eq 'text') { return [string]$Document.text }
    if ($type -eq 'hardBreak') { return "`n" }
    if ($type -eq 'mention' -or $type -eq 'emoji') {
        if ($Document.attrs.text) { return [string]$Document.attrs.text }
        return [string]$Document.attrs.shortName
    }

    $parts = New-Object -TypeName 'System.Collections.Generic.List[string]'
    foreach ($child in @($Document.content)) {
        if ($null -ne $child) {
            $parts.Add((ConvertFrom-JiraDocument -Document $child))
        }
    }

    # Nodes whose children are inline content are joined without a separator
    if ($type -in @('paragraph', 'heading', 'codeBlock')) {
        return (-join $parts)
    }
    return ($parts -join "`n")
}
