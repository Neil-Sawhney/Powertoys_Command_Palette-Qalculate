// Copyright (c) Microsoft Corporation
// The Microsoft Corporation licenses this file to you under the MIT license.
// See the LICENSE file in the project root for more information.

using System;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.CommandPalette.Extensions;
using Microsoft.CommandPalette.Extensions.Toolkit;

namespace Qalculate;

internal sealed partial class QalculatePage : DynamicListPage
{
    private static readonly IconInfo CalculatorIcon = new("\uE8EF");

    private readonly SettingsManager _settings;
    private CancellationTokenSource? _evaluationCts;
    private IListItem[] _items = [];
    private string _query = string.Empty;

    public QalculatePage(SettingsManager settings)
    {
        _settings = settings;
        Icon = CalculatorIcon;
        Title = "Qalculate";
        Name = "Calculate";
        PlaceholderText = "Try mixed units: 5 miles + 10 km, 10 mph * 2 hours, (5 ft + 8 in) to cm";
    }

    public override void UpdateSearchText(string oldSearch, string newSearch)
    {
        _query = newSearch;
        _evaluationCts?.Cancel();
        _evaluationCts = new CancellationTokenSource();
        var token = _evaluationCts.Token;

        if (string.IsNullOrWhiteSpace(_query))
        {
            _items = [];
            RaiseItemsChanged();
            return;
        }

        _items = [
            new ListItem(new NoOpCommand())
            {
                Title = "Calculating...",
                Subtitle = _query,
                Icon = CalculatorIcon,
            },
        ];
        RaiseItemsChanged();

        _ = EvaluateAsync(_query, token);
    }

    public override IListItem[] GetItems() => _items;

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
                    Icon = CalculatorIcon,
                },
            ];
            RaiseItemsChanged();
        }
    }

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
                    Icon = CalculatorIcon,
                },
            ];
        }

        return [
            new ListItem(new CopyTextCommand(result.Output))
            {
                Title = result.Output,
                Subtitle = expression,
                Icon = CalculatorIcon,
            },
        ];
    }
}
