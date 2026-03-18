using System.Text.Json.Serialization;

namespace app.Models;

public record MfaRequiredResponse(
    [property: JsonPropertyName("requiresMfa")] bool RequiresMfa,
    [property: JsonPropertyName("mfaToken")] string MfaToken
);
