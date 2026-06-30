// Copyright (c) Microsoft Corporation
// The Microsoft Corporation licenses this file to you under the MIT license.
// See the LICENSE file in the project root for more information.

using System;
using Microsoft.CommandPalette.Extensions;
using Microsoft.CommandPalette.Extensions.Toolkit;

namespace Qalculate;

internal sealed partial class DeleteHistoryCommand : InvokableCommand
{
    private readonly HistoryStore _store;
    private readonly Guid _id;

    public DeleteHistoryCommand(HistoryStore store, Guid id)
    {
        _store = store;
        _id = id;
        Name = "Remove from history";
        Icon = new IconInfo("\uE74D");
    }

    public override CommandResult Invoke()
    {
        _store.Remove(_id);
        return CommandResult.KeepOpen();
    }
}

internal sealed partial class ClearHistoryCommand : InvokableCommand
{
    private readonly HistoryStore _store;

    public ClearHistoryCommand(HistoryStore store)
    {
        _store = store;
        Name = "Clear calculation history";
        Icon = new IconInfo("\uE894");
    }

    public override CommandResult Invoke()
    {
        if (_store.Clear())
        {
            return CommandResult.ShowToast("Calculation history cleared");
        }

        return CommandResult.KeepOpen();
    }
}
