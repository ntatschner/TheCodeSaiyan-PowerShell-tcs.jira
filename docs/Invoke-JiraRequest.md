---
external help file: tcs.jira-help.xml
Module Name: tcs.jira
online version:
schema: 2.0.0
---

# Invoke-JiraRequest

## SYNOPSIS
Sends a request to the Jira Cloud or Jira Service Management REST API.

## SYNTAX

```
Invoke-JiraRequest [-Method] <String> [[-URIPath] <String>] [[-Resource] <String>] [[-Id] <String>]
 [[-Body] <String>] [[-Query] <Hashtable>] [[-JQL] <String>] [[-MaxQueryPages] <Int32>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Builds the request URL from the context set by Set-JiraContext, adds the Authorization
header, sends the request and returns the parsed response.

Path handling:
- Paths starting with /rest/ are used as they are (for example /rest/agile/1.0/board).
- Paths starting with /servicedeskapi/ are sent to /rest/servicedeskapi/...
- Any other path is sent to the Jira platform API, /rest/api/3/...

Search results (objects with an 'issues' property) are unwrapped to the issues.
Pages are
followed through 'nextPageToken' (JQL search) or a 'nextPage' URL on the same site, up to
-MaxQueryPages.
Requests that fail with HTTP 429 or 503 are retried up to three times.
Errors are terminating and include the HTTP status and Jira's error details, never the
credentials.

## EXAMPLES

### EXAMPLE 1
```
Invoke-JiraRequest -Method Get -Resource issue -Id 'PROJ-123'
```

Gets an issue.

### EXAMPLE 2
```
Invoke-JiraRequest -Method Get -JQL 'project = PROJ AND status = "In Progress"' -Query @{ maxResults = 100 }
```

Returns the issues that match a JQL query.

### EXAMPLE 3
```
Invoke-JiraRequest -Method Get -URIPath '/servicedeskapi/request/SD-42'
```

Gets a Jira Service Management request.

## PARAMETERS

### -Method
The HTTP method: Get, Post, Put, Delete or Patch.

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

### -URIPath
The API path, for example /issue/JRA-9 or /servicedeskapi/request/SD-1.
Takes precedence
over -Resource and -JQL.

```yaml
Type:String
Parameter Sets:   (All)
Aliases:
Required: False
Position: 2Default
Default value: None
Default value: None
Accept pipeline input: False
input:False
Accept pipeline input: False
Accept wildcard characters: False
Accept wildcard characters: False
```

### -Resource
A Jira platform resource shortcut (issue, project, search, user or group), combined with -Id.

```yaml
Type:String
Parameter Sets:   (All)
Aliases:
Required: False
Position: 3Default
Default value: None
Default value: None
Accept pipeline input: False
input:False
Accept pipeline input: False
Accept wildcard characters: False
Accept wildcard characters: False
```

### -Id
The identifier appended to -Resource, for example an issue key.

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

### -Body
The JSON request body.
It is sent as UTF-8.

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

### -Query
Query string parameters.
Keys and values are URL-encoded.
The hashtable is not modified.

```yaml
Type:Hashtable
Parameter Sets:   (All)
Aliases:
Required: False
Position: 6Default
Default value: None
Default value: None
Accept pipeline input: False
input:False
Accept pipeline input: False
Accept wildcard characters: False
Accept wildcard characters: False
```

### -JQL
A JQL query.
Without -URIPath the request goes to the enhanced search endpoint
/rest/api/3/search/jql and returns all navigable fields unless -Query sets 'fields'.

```yaml
Type:String
Parameter Sets:   (All)
Aliases:
Required: False
Position: 7Default
Default value: None
Default value: None
Accept pipeline input: False
input:False
Accept pipeline input: False
Accept wildcard characters: False
Accept wildcard characters: False
```

### -MaxQueryPages
The maximum number of pages to request.
Defaults to 10.

```yaml
Type:
Int32
Parameter Sets:   (All)
Aliases:
Required: False
Position: 8Default
Default value: None
Default value: 10
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

### The parsed response objects.
## NOTES

## RELATED LINKS
