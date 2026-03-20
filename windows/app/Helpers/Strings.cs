using Microsoft.Windows.ApplicationModel.Resources;

namespace app;

internal static class Strings
{
    private static readonly ResourceLoader _loader = new();

    public static string Get(string key) => _loader.GetString(key);

    public static string Format(string key, params object[] args) =>
        string.Format(_loader.GetString(key), args);
}
