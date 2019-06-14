@{
RootModule = 'ScanKernel.psm1'
ModuleVersion = '1.0.0'
#GUID = '6e196b6e-c3d5-464f-ace5-43aff493014b'
Author = 'Hartmut Vogler'
CompanyName = 'TelekomIT'

# Copyright statement for this module
Copyright = '(c) Hartmut Vogler. All rights reserved.'


#Description = 'Imports settings from a config file into the PowerShell scripts command-line parameters and variables.'

PowerShellVersion = '4.0'
FunctionsToExport = 'write-log'

CmdletsToExport = @()

AliasesToExport = @()

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{
        Tags = 'PowerShell','script','utilities'
        LicenseUri = 'https://github.com/itguru/TSecScanSuite/blob/master/LICENSE'
        ProjectUri = 'https://github.com/itguru/TSecScanSuite'
    }

 }

# HelpInfo URI of this module
HelpInfoURI = 'https://github.com/itguru/TSecScanSuite/blob/master/README.md'

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''
}
