---
document type: cmdlet
external help file: PoshJohn.dll-Help.xml
HelpUri: https://github.com/ArmaanMcleod/PoshJohn/blob/main/docs/en-US/Invoke-JohnPasswordCrack.md
Locale: en-US
Module Name: PoshJohn
ms.date: 12/10/2025
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

## DESCRIPTION

{{ Fill in the Description }}

## EXAMPLES

### Example 1

## PARAMETERS

## PARAMETERS

### -CustomPotPath

{{ Fill CustomPotPath Description }}

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

{{ Fill IncrementalMode Description }}

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

{{ Fill InputObject Description }}

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

{{ Fill InputPath Description }}

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

{{ Fill RefreshPot Description }}

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

{{ Fill UnlockedFileDirectoryPath Description }}

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

{{ Fill WordListPath Description }}

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
