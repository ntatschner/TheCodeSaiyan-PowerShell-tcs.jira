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
Get-JiraTicket [-IssueKey] <String> [<CommonParameters>]
```

## DESCRIPTION
Gets the issue from /rest/api/3/issue/\<key\> and returns a summary object with the key, a
browser URL, summary, status, assignee, reporter, dates, description and comments.

Created and Updated are \[datetime\] values.
Description is returned as Jira sends it
(an Atlassian Document Format object in API v3) and DescriptionText holds it as plain text.

Comments are returned as objects with the type name tcs.jira.Comment and the properties
Id, Author, Body, Created, Updated and UpdateAuthor.
Comment bodies are converted to plain
text and the dates are \[datetime\] values.

Issue keys can be piped in, for example from Find-JiraIssue (any object with an IssueKey
or Key property).

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

### EXAMPLE 3
```
= -1d' | Get-JiraTicket
```

Gets every issue updated in the last day, with comments.

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### PSCustomObject
## NOTES

## RELATED LINKS
