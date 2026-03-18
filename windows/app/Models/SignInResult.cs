namespace app.Models;

public abstract record SignInResult
{
    public record Success(AuthResponse Response) : SignInResult();
    public record MfaRequired(string MfaToken) : SignInResult();
}
