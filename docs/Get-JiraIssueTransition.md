---
external help file: tcs.jira-help.xml
Module Name: tcs.jira
online version:
schema: 2.0.0
---

# Get-JiraIssueTransition

## SYNOPSIS
Gets the transitions that can be performed on a Jira Cloud issue.

## SYNTAX

```
Get-JiraIssueTransition [-IssueKey] <String> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Gets the transitions from GET /rest/api/3/issue/\<key\>/transitions for the issue's current
status and the calling account.
Each transition has an id, a name and a 'to' object with
the target status (to.name).

## EXAMPLES

### EXAMPLE 1
```
Get-JiraIssueTransition -IssueKey 'PROJ-123' | Select-Object id, name, @{ n = 'To'; e = { $_.to.name } }
```

Lists the transitions and their target statuses.

## PARAMETERS

### -IssueKey
The issue key or id, for example PROJ-123.
Accepts pipeline input by property name
(IssueKey or Key).

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
