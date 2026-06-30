// Copyright (c) Microsoft Corporation
// The Microsoft Corporation licenses this file to you under the MIT license.
// See the LICENSE file in the project root for more information.

using System.Threading;
using System.Threading.Tasks;

namespace Qalculate;

internal readonly record struct QalculateResult(bool Success, string Output, string? Error);

internal static class QalculateService
{
    public static Task<QalculateResult> EvaluateAsync(
        string expression,
        QalcSession session,
        CancellationToken cancellationToken) =>
        session.EvaluateAsync(expression, cancellationToken);
}
