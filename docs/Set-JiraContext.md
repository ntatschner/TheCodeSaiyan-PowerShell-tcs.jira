---
external help file: tcs.jira-help.xml
Module Name: tcs.jira
online version:
schema: 2.0.0
---

# Set-JiraContext

## SYNOPSIS
Sets the Jira Cloud site and credentials used by the other tcs.jira functions.

## SYNTAX

### Token (Default)
```
Set-JiraContext -JiraUrl <String> -Username <String> -PersonalAccessToken <String> [-PassThru]
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### Credential
```
Set-JiraContext -JiraUrl <String> -Credential <PSCredential> [-PassThru] [-ProgressAction <ActionPreference>]
 [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Stores the Jira site URL and the account e-mail address with its API token for the current
PowerShell session.
Nothing is written to disk.

The API token is kept as a SecureString inside a PSCredential in module scope and the HTTP
Basic Authorization header is built for each request, so the token never appears in the
context object, in verbose output or in error messages.

For compatibility with older scripts the (secret-free) context object is also available as
$global:JiraContext.
It no longer contains an AuthorizationHeader property.
$global:JiraContext is deprecated and will be removed in a future version: use
Get-JiraContext to read the context, Test-JiraContext to check it and Clear-JiraContext
to remove it.

## EXAMPLES

### EXAMPLE 1
```
Set-JiraContext -JiraUrl 'https://contoso.atlassian.net' -Credential (Get-Credential -UserName 'me@contoso.com')
```

Prompts for the API token and sets the context.

### EXAMPLE 2
```
Set-JiraContext -JiraUrl 'https://contoso.atlassian.net' -Username 'me@contoso.com' -PersonalAccessToken $env:JIRA_API_TOKEN
```

Sets the context from a token held in an environment variable.

## PARAMETERS

### -JiraUrl
The base URL of the Jira site, for example https://contoso.atlassian.net.
Must use HTTPS.
A trailing /rest/api/\<version\> path is removed.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Username
The e-mail address of the Atlassian account that owns the API token.

```yaml
Type: String
Parameter Sets: Token
Aliases: EmailAddress

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PersonalAccessToken
The Atlassian API token as plain text.
Prefer -Credential, which keeps the token in a
SecureString from the start.

```yaml
Type: String
Parameter Sets: Token
Aliases: PAT, ApiToken

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Credential
A PSCredential whose user name is the account e-mail address and whose password is the
Atlassian API token.

```yaml
Type: PSCredential
Parameter Sets: Credential
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PassThru
Returns the context object.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhatIf
Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm
Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProgressAction
{{ Fill ProgressAction Description }}

```yaml
Type: ActionPreference
Parameter Sets: (All)
Aliases: proga

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### None, or a PSCustomObject with ConnectionURI, OriginalConnectionURL and Username when -PassThru is used.
## NOTES

## RELATED LINKS
