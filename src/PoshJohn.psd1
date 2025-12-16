@{
    RootModule           = 'PoshJohn.psm1'
    ModuleVersion        = '1.0.1'
    CompatiblePSEditions = @('Core')
    GUID                 = '6181cfe1-1395-4726-8b68-c5782b74a0f0'
    Author               = 'ArmaanMcleod'
    Copyright            = '(c) ArmaanMcleod. All rights reserved.'
    Description          = 'Binary PowerShell module which contains cmdlets to help with extracting and cracking password hashes from password-protected files using John the Ripper (https://www.openwall.com/john/).'
    PowerShellVersion    = '7.2'
    CmdletsToExport      = @(
        'Export-JohnPasswordHash',
        'Invoke-JohnPasswordCrack'
    )
    PrivateData          = @{
        PSData = @{
            Tags         = @(
                'JohnTheRipper'
                'PasswordHash'
                'PasswordCrack'
            )
            LicenseUri   = 'https://github.com/ArmaanMcleod/PoshJohn/blob/main/LICENSE'
            ProjectUri   = 'https://github.com/ArmaanMcleod/PoshJohn'
            ReleaseNotes = 'See https://github.com/ArmaanMcleod/PoshJohn/blob/main/CHANGELOG.md'
        }
    }
}
