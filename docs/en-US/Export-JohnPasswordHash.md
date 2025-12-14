---
document type: cmdlet
external help file: PoshJohn.dll-Help.xml
HelpUri: https://github.com/ArmaanMcleod/PoshJohn/blob/main/docs/en-US/Export-JohnPasswordHash.md
Locale: en-US
Module Name: PoshJohn
ms.date: 12/14/2025
PlatyPS schema version: 2024-05-01
title: Export-JohnPasswordHash
---

# Export-JohnPasswordHash

## SYNOPSIS

Extracts password hashes from password-protected files for use with John the Ripper.

## SYNTAX

### __AllParameterSets

```
Export-JohnPasswordHash -InputPath <string> -OutputPath <string> [-Append] [<CommonParameters>]
```

## ALIASES

## DESCRIPTION

`Export-JohnPasswordHash` extracts password hashes from supported password-protected files (PDF and ZIP) and writes them to a file in a format compatible with John the Ripper.

The cmdlet supports appending to existing hash files and outputs a HashResult object for further processing or cracking.

## EXAMPLES

### Example 1: Extract hashes from a ZIP file

```powershell
Export-JohnPasswordHash -InputPath 'C:\files\protected.zip' -OutputPath 'C:\hashes\hash.txt'
```

Extracts password hashes from the specified ZIP file and writes them to text file.

### Example 2: Extract hashes from a PDF file and append to an existing hash file

```powershell
Export-JohnPasswordHash -InputPath 'C:\files\protected.pdf' -OutputPath 'C:\hashes\hash.txt' -Append
```

Extracts password hashes from the specified PDF file and appends them to the hash file.

## PARAMETERS

### -Append

If specified, appends the extracted hashes to the output file instead of overwriting it.

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

### -InputPath

Specifies the path to the password-protected file from which to extract password hashes.

Supported file formats include PDF and ZIP supported by John the Ripper.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -OutputPath

Specifies the path to the output file where extracted hashes will be written.

The file will be created if it does not exist.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases:
- HashPath
ParameterSets:
- Name: (All)
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

## OUTPUTS

### PoshJohn.Models.HashResult

An object containing the extracted password hashes and associated metadata.

## NOTES

This cmdlet requires John the Ripper and the appropriate 2john utilities to be available on your system. Supported file types depend on the available 2john scripts.

## RELATED LINKS

- [Online Version](https://github.com/ArmaanMcleod/PoshJohn/blob/main/docs/en-US/Export-JohnPasswordHash.md)
