using System.Management.Automation;

namespace PoshJohn.Common;

/// <summary>
/// Provides extension methods for formatting error IDs in PowerShell cmdlets.
/// </summary>
internal static class CommandExtensions
{
    /// <summary>
    /// Formats an error ID for BeginProcessing errors.
    /// </summary>
    /// <param name="cmdlet">The cmdlet instance.</param>
    /// <returns>A formatted error ID string for BeginProcessing errors.</returns>
    public static string FormatBeginProcessingErrorId(this PSCmdlet cmdlet)
    {
        return $"{cmdlet.MyInvocation.MyCommand.Name.Replace("-", "")}BeginProcessingError";
    }

    /// <summary>
    /// Formats an error ID for ProcessRecord errors.
    /// </summary>
    /// <param name="cmdlet">The cmdlet instance.</param>
    /// <returns>A formatted error ID string for ProcessRecord errors.</returns>
    public static string FormatProcessRecordErrorId(this PSCmdlet cmdlet)
    {
        return $"{cmdlet.MyInvocation.MyCommand.Name.Replace("-", "")}ProcessRecordError";
    }
}
