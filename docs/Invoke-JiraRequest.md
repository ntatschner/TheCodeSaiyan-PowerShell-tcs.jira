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
 [[-Body] <Object>] [[-Query] <Hashtable>] [[-JQL] <String>] [[-MaxQueryPages] <Int32>] [-Raw]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Builds the request URL from the context set by Set-JiraContext, adds the Authorization
header, sends the request and returns the parsed response.

Path handling:
- Paths starting with /rest/ are used as they are (for example /rest/agile/1.0/board).
- Paths starting with /servicedeskapi/ are sent to /rest/servicedeskapi/...
- Any other path is sent to the Jira platform API, /rest/api/3/...

Responses are unwrapped and paged, up to -MaxQueryPages pages:
- JQL search results (/rest/api/3/search/jql) are unwrapped to their issues and pages are
  followed through 'nextPageToken'.
Other responses with an 'issues' property (for example
  the bulk create response, which also has 'errors') are returned unchanged.
- Jira platform pages ('values' with 'isLast', 'nextPage', 'startAt' or 'maxResults') are
  unwrapped to their values and the 'nextPage' URL is followed.
- Jira Service Management pages ('values' with 'isLastPage') are unwrapped to their values
  and the '_links.next' URL is followed.
Pagination links are only followed when they point to the site set by Set-JiraContext.
Use -Raw to get the response exactly as Jira sends it, without unwrapping or paging.

Retries: HTTP 429 is retried for every method.
Other 5xx errors are retried only for the
idempotent methods Get, Put and Delete, so a Post (for example creating an issue) is never
sent twice.
At most three attempts are made; the wait honours the Retry-After header
(capped at 60 seconds) and is otherwise 2, then 4 seconds.

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

### EXAMPLE 4
```
Invoke-JiraRequest -Method Post -URIPath '/issue/bulk' -Body @{ issueUpdates = $updates } -Raw
```

Creates issues in bulk and returns the whole response, including its 'errors'.

## PARAMETERS

### -Method
The HTTP method: Get, Post, Put, Delete or Patch.

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

### -URIPath
The API path, for example /issue/JRA-9 or /servicedeskapi/request/SD-1.
Takes precedence
over -Resource and -JQL.

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

### -Resource
A Jira platform resource shortcut (issue, project, search, user or group), combined with -Id.
'search' is sent to the enhanced JQL search endpoint /rest/api/3/search/jql and does not
take -Id.

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

### -Id
The identifier appended to -Resource, for example an issue key.
It is URL-encoded as one
path segment, so it cannot add further path segments or a query string; use -URIPath for
sub-resources such as /issue/PROJ-1/transitions.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Body
The request body.
A string is sent as it is (it should be JSON).
Any other object, such
as a hashtable, is converted to JSON (depth 20).

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Query
Query string parameters.
Keys and values are URL-encoded.
The hashtable is not modified.

```yaml
Type: Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: 6
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -JQL
A JQL query.
Without -URIPath the request goes to the enhanced search endpoint
/rest/api/3/search/jql and returns all navigable fields unless -Query sets 'fields'.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 7
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -MaxQueryPages
The maximum number of pages to request.
Defaults to 10.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 8
Default value: 10
Accept pipeline input: False
Accept wildcard characters: False
```

### -Raw
Returns the response exactly as Jira sends it: search results and pages are not unwrapped
and only one request is made.

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

### The parsed response objects.
## NOTES

## RELATED LINKS
