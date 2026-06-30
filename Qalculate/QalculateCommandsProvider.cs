// Copyright (c) Microsoft Corporation
// The Microsoft Corporation licenses this file to you under the MIT license.
// See the LICENSE file in the project root for more information.

using Microsoft.CommandPalette.Extensions;
using Microsoft.CommandPalette.Extensions.Toolkit;

namespace Qalculate;

public partial class QalculateCommandsProvider : CommandProvider
{
    private readonly ICommandItem[] _commands;
    private readonly SettingsManager _settings = new();

    public QalculateCommandsProvider()
    {
        DisplayName = "PowerQalc";
        Icon = IconHelpers.FromRelativePath("Assets\\StoreLogo.png");
        Settings = _settings.Settings;

        var page = new QalculatePage(_settings);
        _commands = [
            new CommandItem(page)
            {
                Title = DisplayName,
                MoreCommands =
                [
                    new CommandContextItem(new ClearHistoryCommand(_settings.History)),
                ],
            },
        ];
    }

    public override ICommandItem[] TopLevelCommands() => _commands;
}
