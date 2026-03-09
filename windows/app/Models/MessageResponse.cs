using System.Text.Json.Serialization;

namespace app.Models;

public record MessageResponse(
    [property: JsonPropertyName("message")] string Message
);
