---
external help file: tcs.jira-help.xml
Module Name: tcs.jira
online version:
schema: 2.0.0
---

# Get-JiraTicket

## SYNOPSIS
Gets a Jira Cloud issue with its comments.

## SYNTAX

```
Get-JiraTicket [-IssueKey] <String> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Gets the issue from /rest/api/3/issue/\<key\> and returns a summary object with the key, a
browser URL, summary, status, assignee, reporter, dates, description and comments.

Comments are returned as JiraComment objects.
Comment bodies (Atlassian Document Format in
API v3) are converted to plain text.
The description is returned as Jira sends it.

## EXAMPLES

### EXAMPLE 1
```
Get-JiraTicket -IssueKey 'PROJ-123'
```

Gets issue PROJ-123.

### EXAMPLE 2
```
(Get-JiraTicket -IssueKey 'PROJ-123').Comments | Select-Object Author, Created, Body
```

Lists the comments on an issue.

## PARAMETERS

### -IssueKey
The issue key, for example PROJ-123.

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
