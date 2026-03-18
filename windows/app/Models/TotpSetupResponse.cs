using System.Text.Json.Serialization;

namespace app.Models;

public record TotpSetupResponse(
    [property: JsonPropertyName("secret")] string Secret,
    [property: JsonPropertyName("uri")] string Uri
);
