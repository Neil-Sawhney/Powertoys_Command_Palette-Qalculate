// Copyright (c) Microsoft Corporation
// The Microsoft Corporation licenses this file to you under the MIT license.
// See the LICENSE file in the project root for more information.

using System;

namespace Qalculate;

internal enum HistoryEntryKind
{
    Calculation = 0,
    Help = 1,
}

internal sealed class HistoryItem
{
    public Guid Id { get; set; } = Guid.NewGuid();

    public HistoryEntryKind Kind { get; set; } = HistoryEntryKind.Calculation;

    public string Query { get; set; } = string.Empty;

    public string Result { get; set; } = string.Empty;

    public DateTime Timestamp { get; set; } = DateTime.UtcNow;

    public HistoryItem()
    {
    }

    public HistoryItem(string query, string result)
    {
        Query = query;
        Result = result;
        Timestamp = DateTime.UtcNow;
    }
}
