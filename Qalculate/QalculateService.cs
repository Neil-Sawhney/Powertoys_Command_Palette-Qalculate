// Copyright (c) Microsoft Corporation
// The Microsoft Corporation licenses this file to you under the MIT license.
// See the LICENSE file in the project root for more information.

using System.Diagnostics;
using System.Threading;
using System.Threading.Tasks;

namespace Qalculate;

internal readonly record struct QalculateResult(bool Success, string Output, string? Error);

internal static class QalculateService
{
    private const int TimeoutMilliseconds = 2000;

    public static async Task<QalculateResult> EvaluateAsync(
        string expression,
        QalcPathInfo qalc,
        CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(expression))
        {
            return new QalculateResult(false, string.Empty, null);
        }

        var startInfo = new ProcessStartInfo
        {
            FileName = qalc.ExecutablePath,
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            UseShellExecute = false,
            CreateNoWindow = true,
        };

        if (!string.IsNullOrEmpty(qalc.WorkingDirectory))
        {
            startInfo.WorkingDirectory = qalc.WorkingDirectory;
        }

        startInfo.ArgumentList.Add("-t");
        startInfo.ArgumentList.Add("-m");
        startInfo.ArgumentList.Add(TimeoutMilliseconds.ToString());
        startInfo.ArgumentList.Add(expression.Trim());

        using var process = new Process { StartInfo = startInfo };

        if (!process.Start())
        {
            return new QalculateResult(false, string.Empty, "Failed to start qalc.");
        }

        var outputTask = process.StandardOutput.ReadToEndAsync(cancellationToken);
        var errorTask = process.StandardError.ReadToEndAsync(cancellationToken);

        await process.WaitForExitAsync(cancellationToken).ConfigureAwait(false);

        cancellationToken.ThrowIfCancellationRequested();

        var output = (await outputTask.ConfigureAwait(false)).Trim();
        var error = (await errorTask.ConfigureAwait(false)).Trim();

        if (!string.IsNullOrEmpty(error))
        {
            return new QalculateResult(false, output, error);
        }

        return new QalculateResult(true, output, null);
    }
}
