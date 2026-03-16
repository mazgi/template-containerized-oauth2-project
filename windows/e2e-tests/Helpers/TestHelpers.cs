using System;
using System.Net.Http;
using System.Text;
using System.Text.Json;
using System.Text.RegularExpressions;
using System.Threading;

namespace E2ETests.Helpers;

public static class TestHelpers
{
    private static int _counter;
    private static readonly HttpClient Http = new() { Timeout = TimeSpan.FromSeconds(10) };

    private const string BackendURL = "http://localhost:4000";
    private const string MailpitURL = "http://localhost:8025";

    public static string UniqueEmail(string prefix = "e2e")
    {
        var count = Interlocked.Increment(ref _counter);
        return $"{prefix}_{DateTimeOffset.UtcNow.ToUnixTimeMilliseconds()}_{count}@example.com";
    }

    public const string DefaultPassword = "Password1!";

    public static string PostJson(string url, string body)
    {
        var content = new StringContent(body, Encoding.UTF8, "application/json");
        var response = Http.PostAsync(url, content).GetAwaiter().GetResult();
        return response.Content.ReadAsStringAsync().GetAwaiter().GetResult();
    }

    public static string GetVerificationToken(string email)
    {
        for (int i = 0; i < 20; i++)
        {
            try
            {
                var searchUrl = $"{MailpitURL}/api/v1/search?query=to:{email}";
                var response = Http.GetStringAsync(searchUrl).GetAwaiter().GetResult();
                using var doc = JsonDocument.Parse(response);
                var messages = doc.RootElement.GetProperty("messages");
                if (messages.GetArrayLength() > 0)
                {
                    var msgId = messages[0].GetProperty("ID").GetString();
                    var msgResponse = Http.GetStringAsync($"{MailpitURL}/api/v1/message/{msgId}").GetAwaiter().GetResult();
                    using var msgDoc = JsonDocument.Parse(msgResponse);
                    var html = "";
                    if (msgDoc.RootElement.TryGetProperty("HTML", out var htmlProp))
                        html += htmlProp.GetString();
                    if (msgDoc.RootElement.TryGetProperty("Text", out var textProp))
                        html += textProp.GetString();

                    var match = Regex.Match(html ?? "", @"[?&]token=([a-f0-9-]+)");
                    if (match.Success)
                        return match.Groups[1].Value;
                }
            }
            catch { }
            Thread.Sleep(500);
        }
        throw new Exception($"Verification email not found for {email}");
    }

    public static string GetPasswordResetToken(string email)
    {
        for (int i = 0; i < 20; i++)
        {
            try
            {
                var searchUrl = $"{MailpitURL}/api/v1/search?query=to:{email}";
                var response = Http.GetStringAsync(searchUrl).GetAwaiter().GetResult();
                using var doc = JsonDocument.Parse(response);
                var messages = doc.RootElement.GetProperty("messages");
                for (int j = 0; j < messages.GetArrayLength(); j++)
                {
                    var msgId = messages[j].GetProperty("ID").GetString();
                    var msgResponse = Http.GetStringAsync($"{MailpitURL}/api/v1/message/{msgId}").GetAwaiter().GetResult();
                    using var msgDoc = JsonDocument.Parse(msgResponse);
                    var body = "";
                    if (msgDoc.RootElement.TryGetProperty("HTML", out var htmlProp))
                        body += htmlProp.GetString();
                    if (msgDoc.RootElement.TryGetProperty("Text", out var textProp))
                        body += textProp.GetString();

                    if ((body ?? "").Contains("reset-password") || (body ?? "").Contains("Password Reset"))
                    {
                        var match = Regex.Match(body ?? "", @"[?&]token=([a-f0-9-]+)");
                        if (match.Success)
                            return match.Groups[1].Value;
                    }
                }
            }
            catch { }
            Thread.Sleep(500);
        }
        throw new Exception($"Password reset email not found for {email}");
    }

    public static void CreateVerifiedUser(string email, string password = DefaultPassword)
    {
        PostJson($"{BackendURL}/auth/signup", $"{{\"email\":\"{email}\",\"password\":\"{password}\"}}");
        var token = GetVerificationToken(email);
        PostJson($"{BackendURL}/auth/verify-email", $"{{\"token\":\"{token}\"}}");
    }
}
