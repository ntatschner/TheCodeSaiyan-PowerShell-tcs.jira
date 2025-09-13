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
# PowerShellVersion = ''

# Name of the PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# DotNetFrameworkVersion = ''

# Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# ClrVersion = ''

# Processor architecture (None, X86, Amd64) required by this module
# ProcessorArchitecture = ''

# Modules that must be imported into the global environment prior to importing this module
RequiredModules = @('rsy.core')

# Assemblies that must be loaded prior to importing this module
# RequiredAssemblies = @()

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
ScriptsToProcess = @('Classes\JiraComment.ps1')

# Type files (.ps1xml) to be loaded when importing this module
# TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
# FormatsToProcess = @()

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

# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
CmdletsToExport = @()

# Variables to export from this module
VariablesToExport = @()

# Aliases to export from this module
AliasesToExport = @()

# List of private data to pass to the module specified in RootModule/ModuleToProcess. This data is passed as a Hashtable. The keys of the hashtable can be used as variables in the module.
# Updated for:
# - Update-JiraTicket: Added parameter sets for -MarkDone and -MarkResolved (mutually exclusive)
# - Update-JiraTicket: Added logic for -MarkResolved transition
# - Invoke-JiraRequest: Enhanced error reporting with HTTP status code
# - General: Improved error handling and parameter validation
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        # Tags = @()

        # A URL to the license for this module.
        # LicenseUri = ''

        # A URL to the main website for this project.
        # ProjectUri = ''

        # A URL to an icon representing this module.
        # IconUri = ''

        # ReleaseNotes of this module
        # ReleaseNotes = ''

        # Prerelease string of this module
        # Prerelease = ''

        # External module dependencies defined as PowerShellGet module specification.
        # ExternalModuleDependencies = @()

        # For more information on customizing module metadata, see https://aka.ms/PSModuleInfo

    } # End of PSData hashtable
}

# HelpInfo URI of this module
# HelpInfoURI = ''

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}
