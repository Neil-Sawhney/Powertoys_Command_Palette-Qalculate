// Copyright (c) Microsoft Corporation
// The Microsoft Corporation licenses this file to you under the MIT license.
// See the LICENSE file in the project root for more information.

using System;
using System.Collections.Generic;
using System.Text.Json.Serialization;

namespace Qalculate;

[JsonSerializable(typeof(HistoryItem[]))]
internal partial class HistoryJsonContext : JsonSerializerContext;
