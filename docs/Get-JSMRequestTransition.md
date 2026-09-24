---
external help file: tcs.jira-help.xml
Module Name: tcs.jira
online version:
schema: 2.0.0
---

# Get-JSMRequestTransition

## SYNOPSIS
Gets the customer transitions of a Jira Service Management request.

## SYNTAX

```
Get-JSMRequestTransition [-IssueKey] <String> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Gets the transitions the calling account can perform on the request from
GET /rest/servicedeskapi/request/\<key\>/transition, following all pages.
Each transition
has an id and a name; use the id with Set-JSMRequestTransition.

## EXAMPLES

### EXAMPLE 1
```
Get-JSMRequestTransition -IssueKey 'SD-42'
```

Lists the transitions of request SD-42.

## PARAMETERS

### -IssueKey
The issue key or id of the request, for example SD-42.
Accepts pipeline input by property
name (IssueKey or Key).

```yaml
Type: String
Parameter Sets: (All)
Aliases: Key

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName)
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

### PSCustomObject. The transition objects from Jira.
## NOTES

## RELATED LINKS
