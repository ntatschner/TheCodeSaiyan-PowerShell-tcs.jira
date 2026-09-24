---
external help file: tcs.jira-help.xml
Module Name: tcs.jira
online version:
schema: 2.0.0
---

# Test-JiraContext

## SYNOPSIS
Checks that the Jira context works by getting the signed-in user.

## SYNTAX

```
Test-JiraContext [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Sends GET /rest/api/3/myself with the context set by Set-JiraContext and returns the user
(accountId, displayName, emailAddress, active, timeZone ...).
Throws a terminating error
when no context is set or the request fails, for example because the API token is wrong
(HTTP 401) or the site URL is not a Jira site.

## EXAMPLES

### EXAMPLE 1
```
Set-JiraContext -JiraUrl 'https://contoso.atlassian.net' -Credential (Get-Credential)
Test-JiraContext | Select-Object displayName, emailAddress
```

Checks the connection and shows who is signed in.

## PARAMETERS

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

### PSCustomObject. The user returned by /rest/api/3/myself.
## NOTES

## RELATED LINKS
