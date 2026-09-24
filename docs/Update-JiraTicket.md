---
external help file: tcs.jira-help.xml
Module Name: tcs.jira
online version:
schema: 2.0.0
---

# Update-JiraTicket

## SYNOPSIS
Updates a Jira Cloud issue: transitions it, changes fields and/or adds a comment.

## SYNTAX

### Default (Default)
```
Update-JiraTicket -IssueKey <String> [-Summary <String>] [-Comment <String>] [-OptionalFields <Hashtable>]
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### MarkResolved
```
Update-JiraTicket -IssueKey <String> [-Summary <String>] [-Comment <String>] [-OptionalFields <Hashtable>]
 [-MarkResolved] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### MarkDone
```
Update-JiraTicket -IssueKey <String> [-Summary <String>] [-Comment <String>] [-OptionalFields <Hashtable>]
 [-MarkDone] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Performs the requested changes in this order, each as a separate REST call:
1.
-MarkDone / -MarkResolved: finds the 'Done' or 'Resolved' transition
   (GET /rest/api/3/issue/\<key\>/transitions) and performs it.
2.
-Summary / -OptionalFields: PUT /rest/api/3/issue/\<key\> with the fields.
3.
-Comment: POST /rest/api/3/issue/\<key\>/comment (the text is sent as an ADF paragraph).

A failed transition or field update writes a non-terminating error and the remaining
changes are still attempted; use -ErrorAction Stop to stop on the first failure.
A failed
comment is a terminating error.
Supports -WhatIf and -Confirm.

## EXAMPLES

### EXAMPLE 1
```
Update-JiraTicket -IssueKey 'PROJ-123' -Comment 'Deployed to production' -MarkDone
```

Transitions the issue to Done and adds a comment.

### EXAMPLE 2
```
Update-JiraTicket -IssueKey 'PROJ-123' -Summary 'New title' -OptionalFields @{ labels = @('ops', 'urgent') }
```

Changes the summary and labels.

## PARAMETERS

### -IssueKey
The issue key, for example PROJ-123.

```yaml
Type:String
Parameter Sets:   (All)
Aliases:
Required: True
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

### -Summary
A new summary for the issue.

```yaml
Type:String
Parameter Sets:   (All)
Aliases:
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

### -Comment
A plain-text comment to add to the issue.

```yaml
Type:String
Parameter Sets:   (All)
Aliases:
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

### -OptionalFields
A hashtable of other fields to set, keyed by field id, for example @{ labels = @('ops') }.

```yaml
Type:Hashtable
Parameter Sets:   (All)
Aliases:
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

### -MarkDone
Transitions the issue to Done.

```yaml
Type:Switch
Parameter Sets: MarkDone
Aliases:
Required: True
Position:Named
Default value: None
Default value: None
Default value: False
Accept pipeline input: False
input:False
Accept pipeline input: False
Accept wildcard characters: False
Accept wildcard characters: False
```

### -MarkResolved
Transitions the issue to Resolved.

```yaml
Type:Switch
Parameter Sets: MarkResolved
Aliases:
Required: True
Position:Named
Default value: None
Default value: None
Default value: False
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

### None.
## NOTES

## RELATED LINKS
