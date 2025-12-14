---
document type: cmdlet
external help file: PoshJohn.dll-Help.xml
HelpUri: https://github.com/ArmaanMcleod/PoshJohn/blob/main/docs/en-US/Invoke-JohnPasswordCrack.md
Locale: en-US
Module Name: PoshJohn
ms.date: 12/14/2025
PlatyPS schema version: 2024-05-01
title: Invoke-JohnPasswordCrack
---

# Invoke-JohnPasswordCrack

## SYNOPSIS

Attempts to crack password hashes using John the Ripper, supporting both incremental and wordlist attack modes.

## SYNTAX

### IncrementalWithInputObject

```
Invoke-JohnPasswordCrack -InputObject <HashResult> [-IncrementalMode <string>]
 [-CustomPotPath <string>] [-RefreshPot] [-UnlockedFileDirectoryPath <string>] [<CommonParameters>]
```

### WordListWithInputObject

```
Invoke-JohnPasswordCrack -InputObject <HashResult> -WordListPath <string> [-CustomPotPath <string>]
 [-RefreshPot] [-UnlockedFileDirectoryPath <string>] [<CommonParameters>]
```

### IncrementalWithInputPath

```
Invoke-JohnPasswordCrack -InputPath <string> [-IncrementalMode <string>] [-CustomPotPath <string>]
 [-RefreshPot] [-UnlockedFileDirectoryPath <string>] [<CommonParameters>]
```

### WordListWithInputPath

```
Invoke-JohnPasswordCrack -InputPath <string> -WordListPath <string> [-CustomPotPath <string>]
 [-RefreshPot] [-UnlockedFileDirectoryPath <string>] [<CommonParameters>]
```

## ALIASES

## DESCRIPTION

`Invoke-JohnPasswordCrack` uses John the Ripper to attempt to recover plaintext passwords from password hash files or objects.

It supports both incremental (brute-force) and wordlist-based attacks, and can operate on hash files or HashResult objects produced by `Export-JohnPasswordHash`.

The cmdlet can also refresh the pot file, specify custom output locations, and save unlocked files to a directory.

## EXAMPLES

### Example 1: Incremental attack with default mode

```powershell
Invoke-JohnPasswordCrack -InputPath 'C:\hashes\hash.txt'
```

Attempts to crack the hashes in text file using John the Ripper's default incremental mode without specifying `-IncrementalMode`.

### Example 2: Crack hashes with a wordlist

```powershell
Invoke-JohnPasswordCrack -InputPath 'C:\hashes\hash.txt' -WordListPath 'C:\wordlists\rockyou.txt'
```

Attempts to crack the hashes in the text file using the specified wordlist.

### Example 3: Incremental mode with custom pot file

```powershell
Invoke-JohnPasswordCrack -InputPath 'C:\hashes\hash.txt' -IncrementalMode 'ascii' -CustomPotPath 'C:\john\custom.pot'
```

Runs an incremental attack using the `'ascii'` mode and stores cracked passwords in a custom pot file.

### Example 4: Crack using HashResult object from pipeline

```powershell
Export-JohnPasswordHash -InputPath 'C:\files\protected.zip' -OutputPath 'C:\hashes\hash.txt' | Invoke-JohnPasswordCrack -WordListPath 'C:\wordlists\rockyou.txt'
```

Extracts hashes and immediately attempts to crack them using a wordlist.

### Example 5: Save unlocked files to a directory

```powershell
Invoke-JohnPasswordCrack -InputPath 'C:\hashes\hash.txt' -WordListPath 'C:\wordlists\rockyou.txt' -UnlockedFileDirectoryPath 'C:\unlocked-files'
```

Attempts to crack the hashes in the text file using the specified wordlist and saves any successfully unlocked files to a directory.

## PARAMETERS

### -CustomPotPath

Specifies a custom path for the John the Ripper pot file, which stores cracked passwords.

If not specified, the default pot file is used.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -IncrementalMode

Specifies the John the Ripper incremental mode to use for brute-force attacks ("digits", "ascii" etc.).

Only used in incremental attack parameter sets.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: IncrementalWithInputPath
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: IncrementalWithInputObject
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -InputObject

Accepts a HashResult object (typically from `Export-JohnPasswordHash`) containing hashes to be cracked.

Enables pipeline support for chaining extraction and cracking.

```yaml
Type: PoshJohn.Models.HashResult
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: IncrementalWithInputObject
  Position: Named
  IsRequired: true
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: WordListWithInputObject
  Position: Named
  IsRequired: true
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -InputPath

Specifies the path to a file containing password hashes to be cracked.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases:
- HashPath
ParameterSets:
- Name: IncrementalWithInputPath
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: WordListWithInputPath
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -RefreshPot

Forces John the Ripper to reload the pot file before cracking, ensuring the latest cracked passwords are used.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -UnlockedFileDirectoryPath

Specifies a directory where files unlocked by successful password cracks will be saved.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -WordListPath

Specifies the path to a wordlist file to use for dictionary attacks.

Required for wordlist attack parameter sets.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases:
- DictionaryPath
ParameterSets:
- Name: WordListWithInputPath
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: WordListWithInputObject
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### PoshJohn.Models.HashResult

An object containing password hashes and associated metadata, as produced by Export-JohnPasswordHash.

## OUTPUTS

### PoshJohn.Models.PasswordCrackResult

An object containing the results of the password cracking operation, including cracked passwords and status information.

## NOTES

This cmdlet requires John the Ripper to be available and properly configured on your system. Some features may depend on the version of John the Ripper in use.

## RELATED LINKS

- [Online Version](https://github.com/ArmaanMcleod/PoshJohn/blob/main/docs/en-US/Invoke-JohnPasswordCrack.md)
