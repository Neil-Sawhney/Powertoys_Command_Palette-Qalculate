// Copyright (c) Microsoft Corporation
// The Microsoft Corporation licenses this file to you under the MIT license.
// See the LICENSE file in the project root for more information.

using System;
using System.IO;

namespace Qalculate;

internal static class QalcPathResolver
{
    private const string DefaultExecutableName = "qalc";

    public static QalcPathInfo Resolve(string? configuredPath)
    {
        if (!string.IsNullOrWhiteSpace(configuredPath) && !IsDefaultToken(configuredPath))
        {
            return new QalcPathInfo(configuredPath.Trim(), null);
        }

        var bundled = GetBundledPath();
        if (bundled.HasValue)
        {
            return bundled.Value;
        }

        return new QalcPathInfo(DefaultExecutableName, null);
    }

    private static bool IsDefaultToken(string path)
    {
        var trimmed = path.Trim();
        return string.Equals(trimmed, DefaultExecutableName, StringComparison.OrdinalIgnoreCase)
            || string.Equals(trimmed, "auto", StringComparison.OrdinalIgnoreCase);
    }

    private static QalcPathInfo? GetBundledPath()
    {
        var baseDirectory = AppContext.BaseDirectory;
        var bundledExe = Path.Combine(baseDirectory, "qalc", "qalc.exe");
        if (!File.Exists(bundledExe))
        {
            return null;
        }

        return new QalcPathInfo(bundledExe, Path.GetDirectoryName(bundledExe));
    }
}

internal readonly record struct QalcPathInfo(string ExecutablePath, string? WorkingDirectory);
