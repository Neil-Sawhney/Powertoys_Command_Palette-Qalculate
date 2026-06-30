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
    private readonly string _filePath;
    private readonly List<HistoryItem> _items = [];
    private readonly Lock _lock = new();

    private int _capacity;

    public event EventHandler? Changed;

    public HistoryStore(string filePath, int capacity)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(filePath);
        ArgumentOutOfRangeException.ThrowIfLessThan(capacity, 1);

        _filePath = filePath;
        _capacity = capacity;
        _items.AddRange(LoadFromDiskSafe());
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
