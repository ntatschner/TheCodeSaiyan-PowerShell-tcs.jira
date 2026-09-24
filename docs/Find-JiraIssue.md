---
external help file: tcs.jira-help.xml
Module Name: tcs.jira
online version:
schema: 2.0.0
---

# Find-JiraIssue

## SYNOPSIS
Finds Jira Cloud issues with a JQL query.

## SYNTAX

```
Find-JiraIssue [-JQL] <String> [-Fields <String[]>] [-MaxResults <Int32>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
Searches with the enhanced JQL search endpoint (GET /rest/api/3/search/jql), follows the
nextPageToken pages and returns the issue objects as Jira sends them (id, key, self and
fields) until -MaxResults issues have been returned or there are no more results.

The output can be piped to Get-JiraTicket, Update-JiraTicket and Update-JSMRequest, which
take the issue key from the 'key' property.

## EXAMPLES

### EXAMPLE 1
```
Find-JiraIssue -JQL 'project = PROJ AND assignee = currentUser()' -Fields summary, status
```

Returns your issues in PROJ with their summary and status.

### EXAMPLE 2
```
Find-JiraIssue -JQL 'project = PROJ AND labels = stale' -MaxResults 500 | Update-JiraTicket -Comment 'Closing stale issue' -MarkDone
```

Comments on and closes up to 500 issues.

## PARAMETERS

### -JQL
The JQL query, for example 'project = PROJ AND statusCategory != Done'.
Atlassian requires
a bounded query (one with a search restriction).

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

### -Fields
The fields to return for each issue, for example 'summary', 'status'.
Defaults to
'*navigable'.
Use 'key' or 'id' alone for the fastest search.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: @('*navigable')
Accept pipeline input: False
Accept wildcard characters: False
```

### -MaxResults
The maximum number of issues to return.
Defaults to 100.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 100
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

### PSCustomObject. The issue objects from the search response.
## NOTES

## RELATED LINKS
