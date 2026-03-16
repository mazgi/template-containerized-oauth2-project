#if DEBUG
using Windows.Storage;

namespace app.Services;

public static class DebugSettings
{
    private const string ApiBaseUrlKey = "debug_api_base_url";

    public static string? ApiBaseUrl
    {
        get => ApplicationData.Current.LocalSettings.Values[ApiBaseUrlKey] as string;
        set
        {
            if (value is null)
                ApplicationData.Current.LocalSettings.Values.Remove(ApiBaseUrlKey);
            else
                ApplicationData.Current.LocalSettings.Values[ApiBaseUrlKey] = value;
        }
    }
}
#endif
