---
document type: cmdlet
external help file: PoshJohn.dll-Help.xml
HelpUri: https://github.com/ArmaanMcleod/PoshJohn/blob/main/docs/en-US/Invoke-JohnPasswordCrack.md
Locale: en-US
Module Name: PoshJohn
ms.date: 12/08/2025
PlatyPS schema version: 2024-05-01
title: Invoke-JohnPasswordCrack
---

# Invoke-JohnPasswordCrack

## SYNOPSIS

{{ Fill in the Synopsis }}

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

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

{{ Fill in the Description }}

## EXAMPLES

### Example 1



## PARAMETERS

### -CustomPotPath

Path to the custom pot file.

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

Incremental mode.

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

Hash Input Object.

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

Path to the file containing password hashes to crack.

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

Refresh the pot file.

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

Directory path for unlocked files

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

Path to the word list file.

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

{{ Fill in the Description }}

## OUTPUTS

### PoshJohn.Models.PasswordCrackResult

{{ Fill in the Description }}

## NOTES

{{ Fill in the Notes }}


## RELATED LINKS

- [Online Version]()
