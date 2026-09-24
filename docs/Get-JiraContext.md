---
external help file: tcs.jira-help.xml
Module Name: tcs.jira
online version:
schema: 2.0.0
---

# Get-JiraContext

## SYNOPSIS
Gets the Jira connection context of the current session, without secrets.

## SYNTAX

```
Get-JiraContext [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Returns the site URL and user name set by Set-JiraContext.
The API token is never
returned.
Returns nothing when no context is set.

Use this instead of $global:JiraContext, which is deprecated.

## EXAMPLES

### EXAMPLE 1
```
Get-JiraContext
```

Shows the site and user the tcs.jira functions connect with.

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

### PSCustomObject with ConnectionURI, OriginalConnectionURL and Username, or nothing.
## NOTES

## RELATED LINKS
