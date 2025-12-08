using System.Management.Automation;

namespace PoshJohn.Common;

internal static class CommandExtensions
{
    public static string FormatBeginProcessingErrorId(this PSCmdlet cmdlet)
    {
        return $"{cmdlet.MyInvocation.MyCommand.Name.Replace("-", "")}BeginProcessingError";
    }

    public static string FormatProcessRecordErrorId(this PSCmdlet cmdlet)
    {
        return $"{cmdlet.MyInvocation.MyCommand.Name.Replace("-", "")}ProcessRecordError";
    }
}
