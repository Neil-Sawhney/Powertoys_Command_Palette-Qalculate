// Copyright (c) Microsoft Corporation
// The Microsoft Corporation licenses this file to you under the MIT license.
// See the LICENSE file in the project root for more information.

using System;
using System.IO;
using Microsoft.CommandPalette.Extensions;
using Microsoft.CommandPalette.Extensions.Toolkit;

namespace Qalculate;

internal sealed class SettingsManager : IDisposable
{
    private const string DefaultQalcPath = "auto";
    private const string DefaultMaxHistory = "50";
    private const string SettingsFolderName = "neil-sawhney.powerqalc";

    private readonly Settings _settings;
    private readonly string _settingsDirectory;
    private QalcSession? _session;
    private string? _sessionQalcPath;

    public SettingsManager()
    {
        _settings = new Settings();

        _settings.Add(new TextSetting(
            "qalcPath",
            "qalc executable",
            "Leave as \"auto\" to use the bundled copy or qalc on PATH. Or set a full path to qalc.exe.",
            DefaultQalcPath));

        _settings.Add(new ToggleSetting(
            "saveHistory",
            "Save calculation history",
            "Save when you copy a result (Enter) or press Ctrl+Enter. Live previews are not saved.",
            true));

        _settings.Add(new TextSetting(
            "maxHistory",
            "Maximum history entries",
            "Oldest entries are removed when this limit is reached.",
            DefaultMaxHistory));

        _settingsDirectory = Utilities.BaseSettingsPath(SettingsFolderName);
        Directory.CreateDirectory(_settingsDirectory);

        History = new HistoryStore(
            Path.Combine(_settingsDirectory, "calculation_history.json"),
            MaxHistoryEntries);

        _settings.SettingsChanged += OnSettingsChanged;
    }

    public Settings Settings => _settings;

    public HistoryStore History { get; }

    public QalcPathInfo QalcPath =>
        QalcPathResolver.Resolve(
            _settings.TryGetSetting("qalcPath", out string? path) ? path : DefaultQalcPath);

    public QalcSession Session
    {
        get
        {
            var qalcPath = QalcPath;
            var executablePath = qalcPath.ExecutablePath;
            if (_session is null || !string.Equals(_sessionQalcPath, executablePath, StringComparison.OrdinalIgnoreCase))
            {
                _session?.Dispose();
                _session = new QalcSession(
                    qalcPath,
                    Path.Combine(_settingsDirectory, "qalc-user"));
                _sessionQalcPath = executablePath;
            }

            return _session;
        }
    }

    public bool SaveHistory =>
        !_settings.TryGetSetting("saveHistory", out bool save) || save;

    public int MaxHistoryEntries
    {
        get
        {
            if (_settings.TryGetSetting("maxHistory", out string? value)
                && int.TryParse(value, out var parsed)
                && parsed > 0)
            {
                return parsed;
            }

            return int.Parse(DefaultMaxHistory, System.Globalization.CultureInfo.InvariantCulture);
        }
    }

    public void Dispose() => _session?.Dispose();

    private void OnSettingsChanged(object? sender, Settings e)
    {
        History.SetCapacity(MaxHistoryEntries);

        if (_settings.TryGetSetting("qalcPath", out string? _))
        {
            var executablePath = QalcPath.ExecutablePath;
            if (_session is not null
                && !string.Equals(_sessionQalcPath, executablePath, StringComparison.OrdinalIgnoreCase))
            {
                _session.Dispose();
                _session = null;
                _sessionQalcPath = null;
            }
        }
    }
}
