using System;
using System.Text.Json;
using System.Threading.Tasks;
using CommunityToolkit.Mvvm.ComponentModel;
using Windows.Storage;
using app.Models;
using app.Services;

namespace app.ViewModels;

public enum ThemeMode
{
    System,
    Light,
    Dark,
}

public static class ThemeModeExtensions
{
    public static string ToApiValue(this ThemeMode mode) => mode switch
    {
        ThemeMode.Light => "light",
        ThemeMode.Dark => "dark",
        _ => "system",
    };

    public static string ToLabel(this ThemeMode mode) => mode switch
    {
        ThemeMode.Light => "Light",
        ThemeMode.Dark => "Dark",
        _ => "System",
    };

    public static ThemeMode FromApiValue(string? value) => value switch
    {
        "light" => ThemeMode.Light,
        "dark" => ThemeMode.Dark,
        _ => ThemeMode.System,
    };
}

public partial class AuthViewModel : ObservableObject
{
    private const string TokensKey = "auth_tokens";
    private readonly ApiClient _api = ApiClient.Shared;

    [ObservableProperty]
    private UserProfile? _user;

    [ObservableProperty]
    private string? _accessToken;

    [ObservableProperty]
    private bool _isAuthenticated;

    [ObservableProperty]
    private bool _isLoading;

    [ObservableProperty]
    private bool _isRestoringSession = true;

    [ObservableProperty]
    private string? _errorMessage;

    [ObservableProperty]
    private ThemeMode _themeMode = ThemeMode.System;

    public event Action? AuthStateChanged;
    public event Action? ThemeChanged;

    public async Task InitializeAsync()
    {
        await RestoreSessionAsync();
        IsRestoringSession = false;
    }

    public async Task SignInAsync(string email, string password)
    {
        await PerformAsync(async () =>
        {
            var res = await _api.SignInAsync(email, password);
            Store(res);
        });
    }

    public async Task SignUpAsync(string email, string password)
    {
        await PerformAsync(async () =>
        {
            var res = await _api.SignUpAsync(email, password);
            Store(res);
        });
    }

    public async Task SignInWithAppleAsync()
    {
        try
        {
            await Windows.System.Launcher.LaunchUriAsync(
                new Uri($"{_api.BaseUrl}/auth/apple/native"));
        }
        catch (Exception e)
        {
            ErrorMessage = e.Message;
        }
    }

    public async Task SignInWithGithubAsync()
    {
        try
        {
            await Windows.System.Launcher.LaunchUriAsync(
                new Uri($"{_api.BaseUrl}/auth/github/native"));
        }
        catch (Exception e)
        {
            ErrorMessage = e.Message;
        }
    }

    public async Task SignInWithGoogleAsync()
    {
        try
        {
            await Windows.System.Launcher.LaunchUriAsync(
                new Uri($"{_api.BaseUrl}/auth/google/native"));
        }
        catch (Exception e)
        {
            ErrorMessage = e.Message;
        }
    }

    public async Task SignInWithTwitterAsync()
    {
        try
        {
            await Windows.System.Launcher.LaunchUriAsync(
                new Uri($"{_api.BaseUrl}/auth/twitter/native"));
        }
        catch (Exception e)
        {
            ErrorMessage = e.Message;
        }
    }

    public async Task SignInWithDiscordAsync()
    {
        try
        {
            await Windows.System.Launcher.LaunchUriAsync(
                new Uri($"{_api.BaseUrl}/auth/discord/native"));
        }
        catch (Exception e)
        {
            ErrorMessage = e.Message;
        }
    }

    public async Task LinkProviderAsync(string provider)
    {
        if (AccessToken is null) return;
        try
        {
            await Windows.System.Launcher.LaunchUriAsync(
                new Uri($"{_api.BaseUrl}/auth/link/{provider}/native?token={AccessToken}"));
        }
        catch (Exception e)
        {
            ErrorMessage = e.Message;
        }
    }

    public async Task UnlinkProviderAsync(string provider)
    {
        if (AccessToken is null) return;
        await PerformAsync(async () =>
        {
            var updatedUser = await _api.UnlinkProviderAsync(AccessToken, provider);
            User = updatedUser;
        });
    }

    public async Task DeleteAccountAsync()
    {
        if (AccessToken is null) return;
        await PerformAsync(async () =>
        {
            await _api.DeleteAccountAsync(AccessToken);
            SignOut();
        });
    }

    public async Task SetThemeAsync(ThemeMode mode)
    {
        ThemeMode = mode;
        ThemeChanged?.Invoke();
        if (AccessToken is null) return;
        try
        {
            var updated = await _api.UpdatePreferencesAsync(AccessToken, new { theme = mode.ToApiValue() });
            User = updated;
        }
        catch
        {
            // Theme already applied locally; ignore network errors
        }
    }

    public async Task HandleOAuthCallbackAsync(Uri uri)
    {
        var query = new UriQueryParser(uri.Query);

        // Account linking callback — refresh user profile
        var linked = query.Get("linked");
        if (linked is not null)
        {
            if (AccessToken is not null)
            {
                try
                {
                    var profile = await _api.MeAsync(AccessToken);
                    User = profile;
                    AuthStateChanged?.Invoke();
                }
                catch { }
            }
            return;
        }

        var accessToken = query.Get("accessToken");
        var refreshToken = query.Get("refreshToken");
        if (accessToken is null || refreshToken is null) return;

        IsLoading = true;
        ErrorMessage = null;
        try
        {
            var profile = await _api.MeAsync(accessToken);
            StoreTokens(accessToken, refreshToken);
            User = profile;
            AccessToken = accessToken;
            IsAuthenticated = true;
            SyncTheme(profile);
            AuthStateChanged?.Invoke();
        }
        catch (ApiException e)
        {
            ErrorMessage = e.Message;
        }
        catch (Exception e)
        {
            ErrorMessage = e.Message;
        }
        finally
        {
            IsLoading = false;
        }
    }

    public void SignOut()
    {
        ApplicationData.Current.LocalSettings.Values.Remove(TokensKey);
        User = null;
        AccessToken = null;
        IsAuthenticated = false;
        ErrorMessage = null;
        ThemeMode = ThemeMode.System;
        ThemeChanged?.Invoke();
        AuthStateChanged?.Invoke();
    }

    public void ClearError()
    {
        ErrorMessage = null;
    }

    private async Task RestoreSessionAsync()
    {
        var tokens = LoadTokens();
        if (tokens is null) return;

        try
        {
            var profile = await _api.MeAsync(tokens.AccessToken);
            User = profile;
            AccessToken = tokens.AccessToken;
            IsAuthenticated = true;
            SyncTheme(profile);
            AuthStateChanged?.Invoke();
        }
        catch
        {
            try
            {
                var res = await _api.RefreshAsync(tokens.RefreshToken);
                Store(res);
            }
            catch
            {
                SignOut();
            }
        }
    }

    private async Task PerformAsync(Func<Task> action)
    {
        IsLoading = true;
        ErrorMessage = null;
        try
        {
            await action();
        }
        catch (ApiException e)
        {
            ErrorMessage = e.Message;
        }
        catch (Exception e)
        {
            ErrorMessage = e.Message;
        }
        finally
        {
            IsLoading = false;
        }
    }

    private void Store(AuthResponse res)
    {
        StoreTokens(res.AccessToken, res.RefreshToken);
        User = res.User;
        AccessToken = res.AccessToken;
        IsAuthenticated = true;
        SyncTheme(res.User);
        AuthStateChanged?.Invoke();
    }

    private void SyncTheme(UserProfile profile)
    {
        ThemeMode = ThemeModeExtensions.FromApiValue(profile.Preferences?.Theme);
        ThemeChanged?.Invoke();
    }

    private void StoreTokens(string accessToken, string refreshToken)
    {
        var tokens = new StoredTokens(accessToken, refreshToken);
        var json = JsonSerializer.Serialize(tokens);
        ApplicationData.Current.LocalSettings.Values[TokensKey] = json;
    }

    private StoredTokens? LoadTokens()
    {
        if (ApplicationData.Current.LocalSettings.Values.TryGetValue(TokensKey, out var val)
            && val is string json)
        {
            try { return JsonSerializer.Deserialize<StoredTokens>(json); }
            catch { return null; }
        }
        return null;
    }
}

internal sealed class UriQueryParser
{
    private readonly System.Collections.Generic.Dictionary<string, string> _params = new();

    public UriQueryParser(string query)
    {
        if (string.IsNullOrEmpty(query)) return;
        var q = query.StartsWith('?') ? query[1..] : query;
        foreach (var pair in q.Split('&'))
        {
            var parts = pair.Split('=', 2);
            if (parts.Length == 2)
                _params[Uri.UnescapeDataString(parts[0])] = Uri.UnescapeDataString(parts[1]);
        }
    }

    public string? Get(string key) => _params.TryGetValue(key, out var v) ? v : null;
}
