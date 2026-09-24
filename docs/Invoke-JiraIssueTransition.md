---
external help file: tcs.jira-help.xml
Module Name: tcs.jira
online version:
schema: 2.0.0
---

# Invoke-JiraIssueTransition

## SYNOPSIS
Moves a Jira Cloud issue to a status, optionally with a comment.

## SYNTAX

```
Invoke-JiraIssueTransition [-IssueKey] <String> [-Status] <String> [[-Comment] <String>] [-PassThru]
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Gets the issue's transitions (GET /rest/api/3/issue/\<key\>/transitions) and performs the one
that leads to -Status (POST to the same path).
The transition is chosen by its target
status (to.name) first and then by its own name; both comparisons are exact and
case-insensitive.
When no transition matches, a terminating error lists the available
transitions and their target statuses.
-Comment is added afterwards
(POST /rest/api/3/issue/\<key\>/comment).

Supports -WhatIf and -Confirm.
Update-JiraTicket -MarkDone and -MarkResolved use the same
logic with the statuses Done and Resolved.

## EXAMPLES

### EXAMPLE 1
```
Invoke-JiraIssueTransition -IssueKey 'PROJ-123' -Status 'In Progress'
```

Moves the issue to In Progress.

### EXAMPLE 2
```
Find-JiraIssue -JQL 'project = PROJ AND status = "In Review"' | Invoke-JiraIssueTransition -Status Done -Comment 'Approved'
```

Moves every issue in review to Done with a comment.

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

### -Status
The name of the target status, for example 'In Progress' or 'Done'.
A transition name is
also accepted.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Comment
Optional plain-text comment to add after the transition.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PassThru
Returns the transition that was performed.

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

### None, or the transition object when -PassThru is used.
## NOTES

## RELATED LINKS
