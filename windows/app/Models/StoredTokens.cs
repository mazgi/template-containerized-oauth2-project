using System.Text.Json.Serialization;

namespace app.Models;

public record StoredTokens(
    [property: JsonPropertyName("accessToken")] string AccessToken,
    [property: JsonPropertyName("refreshToken")] string RefreshToken
);
