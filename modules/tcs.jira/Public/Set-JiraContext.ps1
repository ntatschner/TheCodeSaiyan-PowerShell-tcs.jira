function Set-JiraContext {
    <#
    .SYNOPSIS
        Sets the Jira Cloud site and credentials used by the other tcs.jira functions.
    .DESCRIPTION
        Stores the Jira site URL and the account e-mail address with its API token for the current
        PowerShell session. Nothing is written to disk.

        The API token is kept as a SecureString inside a PSCredential in module scope and the HTTP
        Basic Authorization header is built for each request, so the token never appears in the
        context object, in verbose output or in error messages.

        For compatibility with older scripts the (secret-free) context object is also available as
        $global:JiraContext. It no longer contains an AuthorizationHeader property.
    .PARAMETER JiraUrl
        The base URL of the Jira site, for example https://contoso.atlassian.net. Must use HTTPS.
        A trailing /rest/api/<version> path is removed.
    .PARAMETER Username
        The e-mail address of the Atlassian account that owns the API token.
    .PARAMETER PersonalAccessToken
        The Atlassian API token as plain text. Prefer -Credential, which keeps the token in a
        SecureString from the start.
    .PARAMETER Credential
        A PSCredential whose user name is the account e-mail address and whose password is the
        Atlassian API token.
    .PARAMETER PassThru
        Returns the context object.
    .EXAMPLE
        Set-JiraContext -JiraUrl 'https://contoso.atlassian.net' -Credential (Get-Credential -UserName 'me@contoso.com')

        Prompts for the API token and sets the context.
    .EXAMPLE
        Set-JiraContext -JiraUrl 'https://contoso.atlassian.net' -Username 'me@contoso.com' -PersonalAccessToken $env:JIRA_API_TOKEN

        Sets the context from a token held in an environment variable.
    .OUTPUTS
        None, or a PSCustomObject with ConnectionURI, OriginalConnectionURL and Username when -PassThru is used.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '',
        Justification = 'The secret-free context is mirrored to $global:JiraContext for backward compatibility with existing scripts.')]
    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'Token')]
    [OutputType([pscustomobject])]
    param (
        [Parameter(Mandatory = $true, HelpMessage = 'The base URL of the Jira instance.')]
        [ValidatePattern('^https://')]
        [string]$JiraUrl,

        [Parameter(Mandatory = $true, ParameterSetName = 'Token')]
        [Alias('EmailAddress')]
        [string]$Username,

        [Parameter(Mandatory = $true, ParameterSetName = 'Token')]
        [Alias('PAT', 'ApiToken')]
        [string]$PersonalAccessToken,

        [Parameter(Mandatory = $true, ParameterSetName = 'Credential')]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential,

        [switch]$PassThru
    )

    # --- Normalise the base URL ---
    $raw = $JiraUrl.Trim().TrimEnd('/')
    $connectionUri = ($raw -replace '(?i)/rest/api/(\d|v\d)+/?$', '').TrimEnd('/')

    if ($PSCmdlet.ParameterSetName -eq 'Token') {
        $secureToken = New-Object -TypeName System.Security.SecureString
        foreach ($character in $PersonalAccessToken.ToCharArray()) {
            $secureToken.AppendChar($character)
        }
        $secureToken.MakeReadOnly()
        $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Username, $secureToken
    }

    if ([string]::IsNullOrWhiteSpace($Credential.UserName)) {
        throw 'A user name (the Atlassian account e-mail address) is required.'
    }

    $context = [pscustomobject]@{
        OriginalConnectionURL = $raw
        ConnectionURI         = $connectionUri
        Username              = $Credential.UserName
        PersonalAccessToken   = ('*' * 8)
    }

    if ($PSCmdlet.ShouldProcess($connectionUri, 'Set Jira connection context')) {
        $script:JiraCredential = $Credential
        $script:JiraContext = $context
        $global:JiraContext = $context
        Write-Verbose "Jira context set. Base='$connectionUri' User='$($Credential.UserName)'"
        if ($PassThru) {
            $context
        }
    }
}
