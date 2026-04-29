#
# Module manifest for module 'tcs.jira'
#
# Generated on: 14/08/2025
#

@{

# Script module or binary module file associated with this manifest.
# RootModule = ''

# Version number of this module.
ModuleVersion = '0.0.2'

# Supported PSEditions
# CompatiblePSEditions = @()

# ID used to uniquely identify this module
GUID = 'dd02af82-ea25-4294-b76e-e072e4d992e9'

# Author of this module
Author = 'Nigel Tatschner'

# Company or vendor of this module
CompanyName = 'Rothesay'

# Copyright statement for this module
Copyright = '(c) 2025 Nigel Tatschner. All rights reserved.'

# Description of the functionality provided by this module
Description = 'Functions to work with Jira'

# Minimum version of the PowerShell engine required by this module
PowerShellVersion = '5.1'

# Modules that must be imported into the global environment prior to importing this module
RequiredModules = @('tcs.core')

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
NestedModules = @(
    'tcs.jira.psm1'
)

# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
FunctionsToExport = @(
    'Invoke-JiraRequest',
    'Set-JiraContext',
    'Get-JiraTicket',
    'New-JiraTicket',
    'Update-JiraTicket',
    'New-JSMRequest',
    'Get-JSMRequest',
    'Update-JSMRequest',
    'Set-JSMRequestTransition'
)

# Cmdlets to export from this module
CmdletsToExport = @()

# Variables to export from this module
VariablesToExport = @()

# Aliases to export from this module
AliasesToExport = @()

PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        # Tags = @()

        # A URL to the license for this module.
        # LicenseUri = ''

        # A URL to the main website for this project.
        # ProjectUri = ''

        # ReleaseNotes of this module
        # ReleaseNotes = ''

    } # End of PSData hashtable
}

}
