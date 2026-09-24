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

Describe 'Get-JSMRequestTransition' {
    It 'Returns the transitions of every page' {
        Mock -ModuleName tcs.jira Invoke-RestMethod {
            if ($Uri -match 'start=1') {
                [pscustomobject]@{ isLastPage = $true; values = @([pscustomobject]@{ id = '2'; name = 'Done' }) }
            }
            else {
                [pscustomobject]@{ isLastPage = $false; values = @([pscustomobject]@{ id = '1'; name = 'Cancel' }); _links = [pscustomobject]@{ next = 'https://contoso.atlassian.net/rest/servicedeskapi/request/SD-1/transition?start=1' } }
            }
        }
        $transitions = @(Get-JSMRequestTransition -IssueKey 'SD-1')
        ($transitions | ForEach-Object name) -join ',' | Should -Be 'Cancel,Done'
        Should -Invoke Invoke-RestMethod -ModuleName tcs.jira -Times 1 -Exactly -ParameterFilter { $Uri -eq "$Base/rest/servicedeskapi/request/SD-1/transition" }
    }
}

Describe 'Get-JSMServiceDesk' {
    BeforeEach {
        Mock -ModuleName tcs.jira Invoke-RestMethod {
            if ($Uri -like '*/servicedesk/4') {
                [pscustomobject]@{ id = '4'; projectKey = 'SD' }
            }
            else {
                [pscustomobject]@{ isLastPage = $true; values = @([pscustomobject]@{ id = '4'; projectKey = 'SD' }, [pscustomobject]@{ id = '5'; projectKey = 'HR' }) }
            }
        }
    }

    It 'Lists service desks' {
        $desks = @(Get-JSMServiceDesk)
        ($desks | ForEach-Object projectKey) -join ',' | Should -Be 'SD,HR'
        Should -Invoke Invoke-RestMethod -ModuleName tcs.jira -Times 1 -Exactly -ParameterFilter { $Uri -eq "$Base/rest/servicedeskapi/servicedesk" }
    }

    It 'Gets one service desk and validates the id' {
        (Get-JSMServiceDesk -ServiceDeskId '4').projectKey | Should -Be 'SD'
        { Get-JSMServiceDesk -ServiceDeskId '4/../x' } | Should -Throw
    }
}

Describe 'Get-JSMRequestType' {
    BeforeEach {
        Mock -ModuleName tcs.jira Invoke-RestMethod { [pscustomobject]@{ isLastPage = $true; values = @([pscustomobject]@{ id = '10'; name = 'Get IT help' }) } }
    }

    It 'Lists the request types of a service desk' {
        (@(Get-JSMRequestType -ServiceDeskId '4'))[0].name | Should -Be 'Get IT help'
        Should -Invoke Invoke-RestMethod -ModuleName tcs.jira -Times 1 -Exactly -ParameterFilter { $Uri -eq "$Base/rest/servicedeskapi/servicedesk/4/requesttype" }
    }

    It 'Gets one request type' {
        Mock -ModuleName tcs.jira Invoke-RestMethod { [pscustomobject]@{ id = '10'; name = 'Get IT help' } }
        (Get-JSMRequestType -ServiceDeskId '4' -RequestTypeId '10').id | Should -Be '10'
        Should -Invoke Invoke-RestMethod -ModuleName tcs.jira -Times 1 -Exactly -ParameterFilter { $Uri -eq "$Base/rest/servicedeskapi/servicedesk/4/requesttype/10" }
    }

    It 'Takes the service desk id from Get-JSMServiceDesk output' {
        $null = [pscustomobject]@{ id = '5'; projectKey = 'HR' } | Get-JSMRequestType
        Should -Invoke Invoke-RestMethod -ModuleName tcs.jira -Times 1 -Exactly -ParameterFilter { $Uri -eq "$Base/rest/servicedeskapi/servicedesk/5/requesttype" }
    }

    It 'Rejects ids that could change the request path' {
        { Get-JSMRequestType -ServiceDeskId '4?x' } | Should -Throw
        { Get-JSMRequestType -ServiceDeskId '4' -RequestTypeId '../1' } | Should -Throw
    }
}
