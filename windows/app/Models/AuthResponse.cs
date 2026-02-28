using System.Text.Json.Serialization;

namespace app.Models;

public record AuthResponse(
    [property: JsonPropertyName("accessToken")] string AccessToken,
    [property: JsonPropertyName("refreshToken")] string RefreshToken,
    [property: JsonPropertyName("user")] UserProfile User
);
