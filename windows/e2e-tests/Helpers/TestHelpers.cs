using System;
using System.Threading;

namespace E2ETests.Helpers;

public static class TestHelpers
{
    private static int _counter;

    public static string UniqueEmail(string prefix = "e2e")
    {
        var count = Interlocked.Increment(ref _counter);
        return $"{prefix}_{DateTimeOffset.UtcNow.ToUnixTimeMilliseconds()}_{count}@example.com";
    }

    public const string DefaultPassword = "Password1!";
}
