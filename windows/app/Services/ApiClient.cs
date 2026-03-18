using System;
using System.Collections.Generic;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;
using System.Threading.Tasks;
using app.Models;

namespace app.Services;

public class ApiException : Exception
{
    public int StatusCode { get; }

    public ApiException(int statusCode, string message) : base(message)
    {
        StatusCode = statusCode;
    }
}

public sealed class ApiClient
{
    public static readonly ApiClient Shared = new(LoadBaseUrl());

    private readonly HttpClient _http;
    private readonly string _defaultBaseUrl;
    public string BaseUrl
    {
        get
        {
#if DEBUG
            var debugUrl = DebugSettings.ApiBaseUrl;
            if (!string.IsNullOrEmpty(debugUrl)) return debugUrl;
#endif
            return _defaultBaseUrl;
        }
    }

    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
    };

    private static string LoadBaseUrl()
    {
        try
        {
            var path = System.IO.Path.Combine(AppContext.BaseDirectory, "appsettings.json");
            var json = System.IO.File.ReadAllText(path);
            using var doc = JsonDocument.Parse(json);
            if (doc.RootElement.TryGetProperty("ApiBaseUrl", out var el))
                return el.GetString() ?? "http://localhost:4000";
        }
        catch { }
        return "http://localhost:4000";
    }

    public ApiClient(string baseUrl = "http://localhost:4000")
    {
        _defaultBaseUrl = baseUrl;
        _http = new HttpClient { Timeout = TimeSpan.FromSeconds(30) };
    }

    public async Task<SignInResult> SignInAsync(string email, string password)
    {
        var json = JsonSerializer.Serialize(new { email, password }, JsonOptions);
        using var request = new HttpRequestMessage(HttpMethod.Post, BaseUrl + "/auth/signin")
        {
            Content = new StringContent(json, Encoding.UTF8, "application/json"),
        };
        var response = await _http.SendAsync(request);
        if (!response.IsSuccessStatusCode)
        {
            var msg = await ParseErrorAsync(response);
            throw new ApiException((int)response.StatusCode, msg);
        }
        var text = await response.Content.ReadAsStringAsync();
        using var doc = JsonDocument.Parse(text);
        if (doc.RootElement.TryGetProperty("requiresMfa", out var mfaProp) && mfaProp.GetBoolean())
        {
            var mfaToken = doc.RootElement.GetProperty("mfaToken").GetString()!;
            return new SignInResult.MfaRequired(mfaToken);
        }
        var authResponse = JsonSerializer.Deserialize<AuthResponse>(text, JsonOptions)!;
        return new SignInResult.Success(authResponse);
    }

    public Task<MessageResponse> SignUpAsync(string email, string password) =>
        PostAsync<MessageResponse>("/auth/signup", new { email, password });

    public Task<MessageResponse> VerifyEmailAsync(string token) =>
        PostAsync<MessageResponse>("/auth/verify-email", new { token });

    public Task<MessageResponse> ResendVerificationAsync(string email) =>
        PostAsync<MessageResponse>("/auth/resend-verification", new { email });

    public Task<AuthResponse> RefreshAsync(string refreshToken) =>
        PostAsync<AuthResponse>("/auth/refresh", new { refreshToken });

    public Task<UserProfile> MeAsync(string accessToken) =>
        GetAsync<UserProfile>("/auth/me", accessToken);

    public Task<List<ItemResponse>> GetItemsAsync(string accessToken) =>
        GetAsync<List<ItemResponse>>("/items", accessToken);

    public Task<ItemResponse> CreateItemAsync(string accessToken, string name) =>
        PostAsync<ItemResponse>("/items", new { name }, accessToken);

    public Task<UserProfile> UnlinkProviderAsync(string accessToken, string provider) =>
        DeleteWithResponseAsync<UserProfile>($"/auth/link/{provider}", accessToken);

    public Task<UserProfile> UpdatePreferencesAsync(string accessToken, object preferences) =>
        PatchAsync<UserProfile>("/users/me/preferences", preferences, accessToken);

    public Task<UserProfile> UpdateEmailAsync(string accessToken, string email) =>
        PatchAsync<UserProfile>("/auth/email", new { email }, accessToken);

    public Task<MessageResponse> ForgotPasswordAsync(string email) =>
        PostAsync<MessageResponse>("/auth/forgot-password", new { email });

    public Task<TotpSetupResponse> TotpSetupAsync(string accessToken) =>
        PostAsync<TotpSetupResponse>("/auth/totp/setup", new { }, accessToken);

    public Task<TotpEnableResponse> TotpEnableAsync(string accessToken, string code) =>
        PostAsync<TotpEnableResponse>("/auth/totp/enable", new { code }, accessToken);

    public Task<MessageResponse> TotpDisableAsync(string accessToken, string code) =>
        PostAsync<MessageResponse>("/auth/totp/disable", new { code }, accessToken);

    public Task<AuthResponse> TotpVerifyAsync(string mfaToken, string code) =>
        PostAsync<AuthResponse>("/auth/totp/verify", new { mfaToken, code });

    public Task<TotpEnableResponse> TotpRegenerateRecoveryCodesAsync(string accessToken, string code) =>
        PostAsync<TotpEnableResponse>("/auth/totp/regenerate-recovery-codes", new { code }, accessToken);

    public async Task DeleteAccountAsync(string accessToken)
    {
        using var request = new HttpRequestMessage(HttpMethod.Delete, BaseUrl + "/auth/account");
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);
        var response = await _http.SendAsync(request);
        if (!response.IsSuccessStatusCode)
        {
            var msg = await ParseErrorAsync(response);
            throw new ApiException((int)response.StatusCode, msg);
        }
    }

    public async Task DeleteItemAsync(string accessToken, string id)
    {
        using var request = new HttpRequestMessage(HttpMethod.Delete, BaseUrl + "/items/" + id);
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);
        var response = await _http.SendAsync(request);
        if (!response.IsSuccessStatusCode)
        {
            var msg = await ParseErrorAsync(response);
            throw new ApiException((int)response.StatusCode, msg);
        }
    }

    private async Task<T> PostAsync<T>(string path, object body, string? accessToken = null)
    {
        var json = JsonSerializer.Serialize(body, JsonOptions);
        using var request = new HttpRequestMessage(HttpMethod.Post, BaseUrl + path)
        {
            Content = new StringContent(json, Encoding.UTF8, "application/json"),
        };
        if (accessToken is not null)
        {
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);
        }
        var response = await _http.SendAsync(request);
        if (!response.IsSuccessStatusCode)
        {
            var msg = await ParseErrorAsync(response);
            throw new ApiException((int)response.StatusCode, msg);
        }
        var text = await response.Content.ReadAsStringAsync();
        return JsonSerializer.Deserialize<T>(text, JsonOptions)!;
    }

    private async Task<T> PatchAsync<T>(string path, object body, string accessToken)
    {
        var json = JsonSerializer.Serialize(body, JsonOptions);
        using var request = new HttpRequestMessage(HttpMethod.Patch, BaseUrl + path)
        {
            Content = new StringContent(json, Encoding.UTF8, "application/json"),
        };
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);
        var response = await _http.SendAsync(request);
        if (!response.IsSuccessStatusCode)
        {
            var msg = await ParseErrorAsync(response);
            throw new ApiException((int)response.StatusCode, msg);
        }
        var text = await response.Content.ReadAsStringAsync();
        return JsonSerializer.Deserialize<T>(text, JsonOptions)!;
    }

    private async Task<T> DeleteWithResponseAsync<T>(string path, string accessToken)
    {
        using var request = new HttpRequestMessage(HttpMethod.Delete, BaseUrl + path);
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);
        var response = await _http.SendAsync(request);
        if (!response.IsSuccessStatusCode)
        {
            var msg = await ParseErrorAsync(response);
            throw new ApiException((int)response.StatusCode, msg);
        }
        var text = await response.Content.ReadAsStringAsync();
        return JsonSerializer.Deserialize<T>(text, JsonOptions)!;
    }

    private async Task<T> GetAsync<T>(string path, string accessToken)
    {
        using var request = new HttpRequestMessage(HttpMethod.Get, BaseUrl + path);
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);
        var response = await _http.SendAsync(request);
        if (!response.IsSuccessStatusCode)
        {
            var msg = await ParseErrorAsync(response);
            throw new ApiException((int)response.StatusCode, msg);
        }
        var text = await response.Content.ReadAsStringAsync();
        return JsonSerializer.Deserialize<T>(text, JsonOptions)!;
    }

    private static async Task<string> ParseErrorAsync(HttpResponseMessage response)
    {
        try
        {
            var text = await response.Content.ReadAsStringAsync();
            using var doc = JsonDocument.Parse(text);
            var root = doc.RootElement;
            if (root.TryGetProperty("message", out var msgEl))
            {
                if (msgEl.ValueKind == JsonValueKind.String)
                    return msgEl.GetString()!;
                if (msgEl.ValueKind == JsonValueKind.Array)
                {
                    var messages = new List<string>();
                    foreach (var item in msgEl.EnumerateArray())
                        messages.Add(item.GetString() ?? "");
                    return string.Join("\n", messages);
                }
            }
        }
        catch { }
        return $"HTTP {(int)response.StatusCode}";
    }
}
