public interface IJwtTokenService
{
    string CreateToken(
        string sessionId,
        AuthenticatedUser user,
        DateTimeOffset expiresAt);
}
