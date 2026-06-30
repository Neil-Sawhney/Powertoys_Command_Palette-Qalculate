// Copyright (c) Microsoft Corporation
// The Microsoft Corporation licenses this file to you under the MIT license.
// See the LICENSE file in the project root for more information.

using System;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.CommandPalette.Extensions;
using Microsoft.CommandPalette.Extensions.Toolkit;

namespace Qalculate;

internal sealed partial class QalculatePage : DynamicListPage
{
    private static readonly IconInfo AppIcon = IconHelpers.FromRelativePath("Assets\\StoreLogo.png");
    private static readonly IconInfo HistoryIcon = new("\uE81C");

    private readonly SettingsManager _settings;
    private CancellationTokenSource? _evaluationCts;
    private IListItem[] _items = [];
    private string _query = string.Empty;

    public QalculatePage(SettingsManager settings)
    {
        _settings = settings;
        Icon = AppIcon;
        Title = "PowerQalc";
        Name = "PowerQalc";
        PlaceholderText = "Try: 5 miles + 10 km, 10 mph * x = 20 mi to min, 240 * 15%, x^2 + 2x = 0, 1 ly to km";

        _settings.History.Changed += OnHistoryChanged;
    }

    public override void UpdateSearchText(string oldSearch, string newSearch)
    {
        _query = newSearch;
        _evaluationCts?.Cancel();
        _evaluationCts = new CancellationTokenSource();
        var token = _evaluationCts.Token;

        if (string.IsNullOrWhiteSpace(_query))
        {
            _items = BuildHistoryItems();
            RaiseItemsChanged();
            return;
        }

        _items = [
            new ListItem(new NoOpCommand())
            {
                Title = "Calculating...",
                Subtitle = _query,
                Icon = AppIcon,
            },
        ];
        RaiseItemsChanged();

        _ = EvaluateAsync(_query, token);
    }

    public override IListItem[] GetItems() => _items;

    private void OnHistoryChanged(object? sender, EventArgs e)
    {
        if (string.IsNullOrWhiteSpace(_query))
        {
            _items = BuildHistoryItems();
            RaiseItemsChanged();
        }
    }

    private async Task EvaluateAsync(string expression, CancellationToken cancellationToken)
    {
        try
        {
            await Task.Delay(300, cancellationToken).ConfigureAwait(false);

            var result = await QalculateService.EvaluateAsync(
                expression,
                _settings.QalcPath,
                cancellationToken).ConfigureAwait(false);

            if (cancellationToken.IsCancellationRequested)
            {
                return;
            }

            if (result.Success && !string.IsNullOrWhiteSpace(result.Output) && _settings.SaveHistory)
            {
                _settings.History.Add(expression.Trim(), result.Output);
            }

            _items = BuildResultItems(expression, result);
            RaiseItemsChanged();
        }
        catch (OperationCanceledException)
        {
        }
        catch (Exception ex)
        {
            if (cancellationToken.IsCancellationRequested)
            {
                return;
            }

            _items = [
                new ListItem(new NoOpCommand())
                {
                    Title = "Evaluation failed",
                    Subtitle = ex.Message,
                    Icon = AppIcon,
                },
            ];
            RaiseItemsChanged();
        }
    }

    private IListItem[] BuildHistoryItems()
    {
        var history = _settings.History.Items;
        if (history.Count == 0)
        {
            return [
                new ListItem(new NoOpCommand())
                {
                    Title = "No recent calculations",
                    Subtitle = "Results you evaluate will appear here",
                    Icon = HistoryIcon,
                },
            ];
        }

        return history
            .OrderByDescending(item => item.Timestamp)
            .Select(item => CreateHistoryListItem(item))
            .ToArray();
    }

    private IListItem CreateHistoryListItem(HistoryItem item) =>
        new ListItem(new CopyTextCommand(item.Result))
        {
            Title = item.Result,
            Subtitle = item.Query,
            Icon = HistoryIcon,
            MoreCommands =
            [
                new CommandContextItem(new DeleteHistoryCommand(_settings.History, item.Id)),
            ],
        };

    private static IListItem[] BuildResultItems(string expression, QalculateResult result)
    {
        if (!result.Success || string.IsNullOrWhiteSpace(result.Output))
        {
            var message = result.Error ?? "No result";
            return [
                new ListItem(new NoOpCommand())
                {
                    Title = message,
                    Subtitle = expression,
                    Icon = AppIcon,
                },
            ];
        }

        return [
            new ListItem(new CopyTextCommand(result.Output))
            {
                Title = result.Output,
                Subtitle = expression,
                Icon = AppIcon,
            },
        ];
    }
}
