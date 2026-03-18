using System.Text.Json.Serialization;

namespace app.Models;

public record UserPreferences(
    [property: JsonPropertyName("theme")] string? Theme = null
);

public record UserProfile(
    [property: JsonPropertyName("id")] string Id,
    [property: JsonPropertyName("email")] string Email,
    [property: JsonPropertyName("emailVerified")] bool EmailVerified = false,
    [property: JsonPropertyName("name")] string? Name = null,
    [property: JsonPropertyName("appleId")] string? AppleId = null,
    [property: JsonPropertyName("githubId")] string? GithubId = null,
    [property: JsonPropertyName("googleId")] string? GoogleId = null,
    [property: JsonPropertyName("twitterId")] string? TwitterId = null,
    [property: JsonPropertyName("discordId")] string? DiscordId = null,
    [property: JsonPropertyName("hasPassword")] bool? HasPassword = null,
    [property: JsonPropertyName("totpEnabled")] bool? TotpEnabled = null,
    [property: JsonPropertyName("socialEmails")] string[]? SocialEmails = null,
    [property: JsonPropertyName("preferences")] UserPreferences? Preferences = null,
    [property: JsonPropertyName("createdAt")] string CreatedAt = "",
    [property: JsonPropertyName("updatedAt")] string UpdatedAt = ""
);
