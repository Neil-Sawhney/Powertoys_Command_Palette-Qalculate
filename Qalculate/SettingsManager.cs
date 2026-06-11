// Copyright (c) Microsoft Corporation
// The Microsoft Corporation licenses this file to you under the MIT license.
// See the LICENSE file in the project root for more information.

using Microsoft.CommandPalette.Extensions;
using Microsoft.CommandPalette.Extensions.Toolkit;

namespace Qalculate;

internal sealed class SettingsManager
{
    private const string DefaultQalcPath = "auto";

    private readonly Settings _settings;

    public SettingsManager()
    {
        _settings = new Settings();

        var qalcPath = new TextSetting(
            "qalcPath",
            "qalc executable",
            "Leave as \"auto\" to use the bundled copy or qalc on PATH. Or set a full path to qalc.exe.",
            DefaultQalcPath);

        _settings.Add(qalcPath);
    }

    public Settings Settings => _settings;

    public QalcPathInfo QalcPath =>
        QalcPathResolver.Resolve(
            _settings.TryGetSetting("qalcPath", out string? path) ? path : DefaultQalcPath);
}
