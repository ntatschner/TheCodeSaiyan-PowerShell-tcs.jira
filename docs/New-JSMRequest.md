---
external help file: tcs.jira-help.xml
Module Name: tcs.jira
online version:
schema: 2.0.0
---

# New-JSMRequest

## SYNOPSIS
Creates a Jira Service Management customer request.

## SYNTAX

```
New-JSMRequest [-ServiceDeskId] <String> [-RequestTypeId] <String> [-Summary] <String>
 [[-Description] <String>] [[-RequestFieldValues] <Hashtable>] [[-Reporter] <String>]
 [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Creates a request through POST /rest/servicedeskapi/request and returns Jira's response
(including issueKey).
The request is raised on behalf of -Reporter when it is given.

## EXAMPLES

### EXAMPLE 1
```
New-JSMRequest -ServiceDeskId '1' -RequestTypeId '10' -Summary 'New laptop' -Reporter 'user@contoso.com'
```

Raises a request on behalf of a customer.

### EXAMPLE 2
```
New-JSMRequest -ServiceDeskId '1' -RequestTypeId '10' -Summary 'New laptop' -RequestFieldValues @{ customfield_10010 = 'Model X' }
```

Raises a request and sets a custom field of the request type.

## PARAMETERS

### -ServiceDeskId
The id of the service desk.

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

### -RequestTypeId
The id of the request type.

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

### -Summary
The request summary.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Description
Optional plain-text description.

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

### -RequestFieldValues
Optional hashtable of other request fields, keyed by field id, for example
@{ customfield_10010 = 'Laptop model X'; priority = @{ name = 'High' } }.
The entries are
added to 'requestFieldValues'; -Summary and -Description take precedence over entries with
the same key.
Get-JSMRequestType shows the request types of a service desk.

```yaml
Type: Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Reporter
Optional e-mail address or account id of the customer the request is raised on behalf of
(sent as raiseOnBehalfOf).
When omitted the request is raised by the account in the context.

```yaml
Type: String
Parameter Sets: (All)
Aliases: RaiseOnBehalfOf

Required: False
Position: 6
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

### PSCustomObject
## NOTES

## RELATED LINKS
