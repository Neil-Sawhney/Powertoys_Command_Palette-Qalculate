// Copyright (c) Microsoft Corporation
// The Microsoft Corporation licenses this file to you under the MIT license.
// See the LICENSE file in the project root for more information.

using System;
using System.Collections.Generic;
using System.IO;
using System.Text.Json;
using System.Threading;

namespace Qalculate;

internal sealed class HistoryStore
{
    internal const string HelpTitle = "Usage & help";
    internal const string HelpSubtitle = "Conversions, percentages, and tips";

    private readonly string _filePath;
    private readonly string _helpDismissedPath;
    private readonly List<HistoryItem> _items = [];
    private readonly Lock _lock = new();

    private int _capacity;
    private bool _helpDismissed;

    public event EventHandler? Changed;

    public HistoryStore(string filePath, int capacity)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(filePath);
        ArgumentOutOfRangeException.ThrowIfLessThan(capacity, 1);

        _filePath = filePath;
        _helpDismissedPath = Path.ChangeExtension(filePath, ".help_dismissed");
        _capacity = capacity;
        _helpDismissed = File.Exists(_helpDismissedPath);
        _items.AddRange(LoadFromDiskSafe());
        if (!_helpDismissed && !_items.Exists(item => item.Kind == HistoryEntryKind.Help))
        {
            if (EnsureHelpEntryNoLock())
            {
                SaveNoLock();
            }
        }

        TrimNoLock();
    }

    public IReadOnlyList<HistoryItem> Items
    {
        get
        {
            lock (_lock)
            {
                return [.. _items];
            }
        }
    }

    public void Add(string query, string result)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(query);
        ArgumentException.ThrowIfNullOrWhiteSpace(result);

        lock (_lock)
        {
            _items.RemoveAll(item =>
                string.Equals(item.Query, query, StringComparison.OrdinalIgnoreCase));

            _items.Add(new HistoryItem(query, result));
            _ = TrimNoLock();
            SaveNoLock();
        }

        Changed?.Invoke(this, EventArgs.Empty);
    }

    public bool Remove(Guid id)
    {
        var removed = false;
        lock (_lock)
        {
            var index = _items.FindIndex(item => item.Id == id);
            if (index >= 0)
            {
                if (_items[index].Kind == HistoryEntryKind.Help)
                {
                    MarkHelpDismissedNoLock();
                }

                _items.RemoveAt(index);
                SaveNoLock();
                removed = true;
            }
        }

        if (removed)
        {
            Changed?.Invoke(this, EventArgs.Empty);
        }

        return removed;
    }

    public bool Clear()
    {
        var cleared = false;
        lock (_lock)
        {
            if (_items.Count > 0)
            {
                _items.Clear();
                _helpDismissed = false;
                TryDeleteHelpDismissedFile();
                EnsureHelpEntryNoLock();
                SaveNoLock();
                cleared = true;
            }
        }

        if (cleared)
        {
            Changed?.Invoke(this, EventArgs.Empty);
        }

        return cleared;
    }

    public void SetCapacity(int capacity)
    {
        ArgumentOutOfRangeException.ThrowIfLessThan(capacity, 1);

        var trimmed = false;
        lock (_lock)
        {
            _capacity = capacity;
            trimmed = TrimNoLock();
            if (trimmed)
            {
                SaveNoLock();
            }
        }

        if (trimmed)
        {
            Changed?.Invoke(this, EventArgs.Empty);
        }
    }

    private bool EnsureHelpEntryNoLock()
    {
        if (_items.Exists(item => item.Kind == HistoryEntryKind.Help))
        {
            return false;
        }

        _items.Add(new HistoryItem
        {
            Kind = HistoryEntryKind.Help,
            Query = HelpSubtitle,
            Result = HelpTitle,
            Timestamp = DateTime.UtcNow.AddYears(-1),
        });

        return true;
    }

    private void MarkHelpDismissedNoLock()
    {
        _helpDismissed = true;
        File.WriteAllText(_helpDismissedPath, "1");
    }

    private void TryDeleteHelpDismissedFile()
    {
        if (File.Exists(_helpDismissedPath))
        {
            File.Delete(_helpDismissedPath);
        }
    }

    private bool TrimNoLock()
    {
        if (_items.Count <= _capacity)
        {
            return false;
        }

        _items.RemoveRange(0, _items.Count - _capacity);
        return true;
    }

    private List<HistoryItem> LoadFromDiskSafe()
    {
        try
        {
            if (!File.Exists(_filePath))
            {
                return [];
            }

            var fileContent = File.ReadAllText(_filePath);
            var items = JsonSerializer.Deserialize(fileContent, HistoryJsonContext.Default.HistoryItemArray) ?? [];
            return [.. items];
        }
        catch
        {
            return [];
        }
    }

    private void SaveNoLock()
    {
        var json = JsonSerializer.Serialize(_items.ToArray(), HistoryJsonContext.Default.HistoryItemArray);
        File.WriteAllText(_filePath, json);
    }
}
