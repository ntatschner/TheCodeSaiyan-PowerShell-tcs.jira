---
external help file: tcs.jira-help.xml
Module Name: tcs.jira
online version:
schema: 2.0.0
---

# New-JiraTicket

## SYNOPSIS
Creates a Jira Cloud issue.

## SYNTAX

```
New-JiraTicket [-ProjectKey] <String> [-IssueType] <String> [-Summary] <String> [[-Description] <String>]
 [[-WorkloadType] <String>] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Creates an issue through POST /rest/api/3/issue and returns Jira's response (id, key and
self link).
The description is sent as a single Atlassian Document Format paragraph.

## EXAMPLES

### EXAMPLE 1
```
New-JiraTicket -ProjectKey 'PROJ' -IssueType 'Task' -Summary 'Rotate certificates' -Description 'Expires next month'
```

Creates a task.

### EXAMPLE 2
```
New-JiraTicket -ProjectKey 'OPS' -IssueType 'Task' -Summary 'Patch servers' -WorkloadType 'BAU' -WhatIf
```

Shows what would be created without calling Jira.

## PARAMETERS

### -ProjectKey
The key of the project, for example PROJ.

```yaml
Type:String
Parameter Sets:   (All)
Aliases:
Required: True
Position: 1Default
Default value: None
Default value: None
Accept pipeline input: False
input:False
Accept pipeline input: False
Accept wildcard characters: False
Accept wildcard characters: False
```

### -IssueType
The issue type name, for example Task or Bug.

```yaml
Type:String
Parameter Sets:   (All)
Aliases:
Required: True
Position: 2Default
Default value: None
Default value: None
Accept pipeline input: False
input:False
Accept pipeline input: False
Accept wildcard characters: False
Accept wildcard characters: False
```

### -Summary
The issue summary.

```yaml
Type:String
Parameter Sets:   (All)
Aliases:
Required: True
Position: 3Default
Default value: None
Default value: None
Accept pipeline input: False
input:False
Accept pipeline input: False
Accept wildcard characters: False
Accept wildcard characters: False
```

### -Description
Optional plain-text description.

```yaml
Type:String
Parameter Sets:   (All)
Aliases:
Required: False
Position: 4Default
Default value: None
Default value: None
Accept pipeline input: False
input:False
Accept pipeline input: False
Accept wildcard characters: False
Accept wildcard characters: False
```

### -WorkloadType
Optional value for the 'Workload Type' select field (customfield_14982).
The field is only
sent when a value is given.

```yaml
Type:String
Parameter Sets:   (All)
Aliases:
Required: False
Position: 5Default
Default value: None
Default value: None
Accept pipeline input: False
input:False
Accept pipeline input: False
Accept wildcard characters: False
Accept wildcard characters: False
```

### -WhatIf
Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type:Switch
Parameter Sets:   (All)
Aliases:wi
Required: False
Position:Named
Default value: None
Default value: None
Default value: None
Accept pipeline input: False
input:False
Accept pipeline input: False
Accept wildcard characters: False
Accept wildcard characters: False
```

### -Confirm
Prompts you for confirmation before running the cmdlet.

```yaml
Type:Switch
Parameter Sets:   (All)
Aliases:cf
Required: False
Position:Named
Default value: None
Default value: None
Default value: None
Accept pipeline input: False
input:False
Accept pipeline input: False
Accept wildcard characters: False
Accept wildcard characters: False
```

### -ProgressAction
{{ Fill ProgressAction Description }}

```yaml
Type:ActionPreference
Parameter Sets:   (All)
Aliases:proga
Required: False
Position:Named
Default value: None
Default value: None
Default value: None
Accept pipeline input: False
input:False
Accept pipeline input: False
Accept wildcard characters: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### PSCustomObject
## NOTES

## RELATED LINKS
