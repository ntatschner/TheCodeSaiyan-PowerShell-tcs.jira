---
external help file: tcs.jira-help.xml
Module Name: tcs.jira
online version:
schema: 2.0.0
---

# Get-JSMRequestType

## SYNOPSIS
Gets the request types of a Jira Service Management service desk.

## SYNTAX

```
Get-JSMRequestType [-ServiceDeskId] <String> [[-RequestTypeId] <String>] [[-MaxQueryPages] <Int32>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Without -RequestTypeId, gets every request type of the service desk from
GET /rest/servicedeskapi/servicedesk/\<id\>/requesttype, following all pages.
With
-RequestTypeId, gets that request type.
Each request type has an id (use it with
New-JSMRequest -RequestTypeId), a name, a description and the ids of its groups.

## EXAMPLES

### EXAMPLE 1
```
Get-JSMRequestType -ServiceDeskId '1' | Select-Object id, name
```

Lists the request types of service desk 1.

### EXAMPLE 2
```
Get-JSMServiceDesk | Where-Object projectKey -EQ 'SD' | Get-JSMRequestType
```

Lists the request types of the SD service desk.

## PARAMETERS

### -ServiceDeskId
The id of the service desk, for example 1.
Accepts pipeline input by property name
(ServiceDeskId, or id from Get-JSMServiceDesk).

```yaml
Type: String
Parameter Sets: (All)
Aliases: id

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -RequestTypeId
The id of one request type.

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

### -MaxQueryPages
The maximum number of pages to request when listing request types.
Defaults to 10.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
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

### PSCustomObject. The request type objects from Jira.
## NOTES

## RELATED LINKS
