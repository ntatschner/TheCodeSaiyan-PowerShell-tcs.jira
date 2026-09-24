BeforeAll {
    $env:TCS_CONFIG_ROOT = Join-Path -Path $TestDrive -ChildPath 'config'
    $env:TCS_SKIP_UPDATE_CHECK = '1'
    $env:TCS_TELEMETRY_OPTOUT = '1'
    $ModuleRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
    Import-Module -Name (Join-Path -Path $ModuleRoot -ChildPath 'tcs.jira.psd1') -Force
    Set-JiraContext -JiraUrl 'https://contoso.atlassian.net' -Username 'user@contoso.com' -PersonalAccessToken 'tok-SECRET-123'
    $Base = 'https://contoso.atlassian.net'
}

AfterAll {
    Remove-Module -Name tcs.jira -Force -ErrorAction SilentlyContinue
}

Describe 'New-JSMRequest' {
    BeforeEach {
        Mock -ModuleName tcs.jira Invoke-RestMethod { [pscustomobject]@{ issueKey = 'SD-1' } }
    }

    It 'Posts the request to the Service Management API' {
        $result = New-JSMRequest -ServiceDeskId '1' -RequestTypeId '10' -Summary 'New laptop' -Description 'Please' -Reporter 'user@contoso.com'
        $result.issueKey | Should -Be 'SD-1'
        Should -Invoke Invoke-RestMethod -ModuleName tcs.jira -Times 1 -Exactly -ParameterFilter {
            $sent = if ($Body) { $Body | ConvertFrom-Json } else { [pscustomobject]@{} }
            $Uri -eq "$Base/rest/servicedeskapi/request" -and $Method -eq 'Post' -and
            $sent.serviceDeskId -eq '1' -and
            $sent.requestTypeId -eq '10' -and
            $sent.requestFieldValues.summary -eq 'New laptop' -and
            $sent.requestFieldValues.description -eq 'Please' -and
            $sent.raiseOnBehalfOf -eq 'user@contoso.com' -and
            -not ($sent.PSObject.Properties.Name -contains 'reporter')
        }
    }

    It 'Omits the description and reporter when not given' {
        $null = New-JSMRequest -ServiceDeskId '1' -RequestTypeId '10' -Summary 'New laptop'
        Should -Invoke Invoke-RestMethod -ModuleName tcs.jira -Times 1 -Exactly -ParameterFilter {
            $sent = if ($Body) { $Body | ConvertFrom-Json } else { [pscustomobject]@{} }
            -not ($sent.requestFieldValues.PSObject.Properties.Name -contains 'description') -and
            -not ($sent.PSObject.Properties.Name -contains 'raiseOnBehalfOf')
        }
    }

    It 'Merges -RequestFieldValues, with -Summary and -Description taking precedence' {
        $null = New-JSMRequest -ServiceDeskId '1' -RequestTypeId '10' -Summary 'New laptop' -Description 'Please' -RequestFieldValues @{ customfield_10010 = 'Model X'; summary = 'ignored'; priority = @{ name = 'High' } }
        Should -Invoke Invoke-RestMethod -ModuleName tcs.jira -Times 1 -Exactly -ParameterFilter {
            $sent = if ($Body) { $Body | ConvertFrom-Json } else { [pscustomobject]@{} }
            $sent.requestFieldValues.customfield_10010 -eq 'Model X' -and
            $sent.requestFieldValues.priority.name -eq 'High' -and
            $sent.requestFieldValues.summary -eq 'New laptop' -and
            $sent.requestFieldValues.description -eq 'Please'
        }
    }

    It 'Does not call Jira with -WhatIf' {
        New-JSMRequest -ServiceDeskId '1' -RequestTypeId '10' -Summary 'S' -WhatIf
        Should -Invoke Invoke-RestMethod -ModuleName tcs.jira -Times 0 -Exactly
    }
}
