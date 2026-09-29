---
external help file: tcs.jira-help.xml
Module Name: tcs.jira
online version:
schema: 2.0.0
---

# Set-JSMRequestTransition

## SYNOPSIS
Transitions a Jira Service Management request to a new status.

## SYNTAX

```
Set-JSMRequestTransition [-IssueKey] <String> [-TransitionId] <String>
 [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Performs a customer transition through POST /rest/servicedeskapi/request/\<key\>/transition.
Get the available transition ids with Get-JSMRequestTransition.

## EXAMPLES

### EXAMPLE 1
```
Set-JSMRequestTransition -IssueKey 'SD-42' -TransitionId '761'
```

Performs transition 761 on request SD-42.

## PARAMETERS

### -IssueKey
The issue key or id of the request, for example SD-42.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -TransitionId
The id of the transition to perform.

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### None. Jira returns no content for a successful transition.
## NOTES

## RELATED LINKS
