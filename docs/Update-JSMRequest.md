---
external help file: tcs.jira-help.xml
Module Name: tcs.jira
online version:
schema: 2.0.0
---

# Update-JSMRequest

## SYNOPSIS
Updates a Jira Service Management request: marks it done, changes fields and/or adds a comment.

## SYNTAX

```
Update-JSMRequest [-IssueKey] <String> [[-Summary] <String>] [[-Comment] <String>] [-Internal]
 [[-OptionalFields] <Hashtable>] [-MarkDone] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION
Performs the requested changes in this order, each as a separate REST call:
1.
-MarkDone: performs the request's 'Done' customer transition
   (GET /rest/servicedeskapi/request/\<key\>/transition, exact name match).
2.
-Summary / -OptionalFields: PUT /rest/api/3/issue/\<key\> with the fields (the Service
   Management API has no request update endpoint).
3.
-Comment: POST /rest/servicedeskapi/request/\<key\>/comment.
The comment is public
   (visible to the customer) unless -Internal is given.

A failed transition (including when there is no 'Done' transition) or field update writes
a non-terminating error and the remaining changes are still attempted; use
-ErrorAction Stop to stop on the first failure.
A failed comment is a terminating error
(the original error from Invoke-JiraRequest).
Supports -WhatIf and -Confirm.

Issue keys can be piped in (any object with an IssueKey or Key property).

## EXAMPLES

### EXAMPLE 1
```
Update-JSMRequest -IssueKey 'SD-42' -Comment 'Laptop shipped' -MarkDone
```

Marks the request done and adds a public comment.

### EXAMPLE 2
```
Update-JSMRequest -IssueKey 'SD-42' -Comment 'Waiting for the supplier' -Internal
```

Adds an internal comment that the customer does not see.

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

### -Summary
A new summary for the request.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Comment
A plain-text comment to add to the request.

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

### -Internal
Adds -Comment as an internal comment, visible to agents only.

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

### -OptionalFields
A hashtable of other fields to set, keyed by field id.

```yaml
Type: Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -MarkDone
Performs the request's 'Done' transition.

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

### None.
## NOTES

## RELATED LINKS
