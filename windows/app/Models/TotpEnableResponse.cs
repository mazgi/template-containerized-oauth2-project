using System.Text.Json.Serialization;

namespace app.Models;

public record TotpEnableResponse(
    [property: JsonPropertyName("recoveryCodes")] string[] RecoveryCodes
);
