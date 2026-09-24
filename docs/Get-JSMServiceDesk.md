---
external help file: tcs.jira-help.xml
Module Name: tcs.jira
online version:
schema: 2.0.0
---

# Get-JSMServiceDesk

## SYNOPSIS
Gets Jira Service Management service desks.

## SYNTAX

```
Get-JSMServiceDesk [[-ServiceDeskId] <String>] [[-MaxQueryPages] <Int32>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
Without -ServiceDeskId, gets every service desk the calling account can see from
GET /rest/servicedeskapi/servicedesk, following all pages.
With -ServiceDeskId, gets that
service desk from GET /rest/servicedeskapi/servicedesk/\<id\>.
Each service desk has an id
(use it with New-JSMRequest and Get-JSMRequestType), projectId, projectName and projectKey.

## EXAMPLES

### EXAMPLE 1
```
Get-JSMServiceDesk | Select-Object id, projectKey, projectName
```

Lists the service desks.

## PARAMETERS

### -ServiceDeskId
The id of one service desk, for example 1.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -MaxQueryPages
The maximum number of pages to request when listing service desks.
Defaults to 10.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: 10
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

### PSCustomObject. The service desk objects from Jira.
## NOTES

## RELATED LINKS
