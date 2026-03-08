using System.Text.Json.Serialization;

namespace app.Models;

public record UserPreferences(
    [property: JsonPropertyName("theme")] string? Theme = null
);

public record UserProfile(
    [property: JsonPropertyName("id")] string Id,
    [property: JsonPropertyName("email")] string Email,
    [property: JsonPropertyName("name")] string? Name,
    [property: JsonPropertyName("appleId")] string? AppleId,
    [property: JsonPropertyName("githubId")] string? GithubId,
    [property: JsonPropertyName("googleId")] string? GoogleId,
    [property: JsonPropertyName("twitterId")] string? TwitterId,
    [property: JsonPropertyName("discordId")] string? DiscordId,
    [property: JsonPropertyName("hasPassword")] bool? HasPassword,
    [property: JsonPropertyName("preferences")] UserPreferences? Preferences = null,
    [property: JsonPropertyName("createdAt")] string CreatedAt = "",
    [property: JsonPropertyName("updatedAt")] string UpdatedAt = ""
);
