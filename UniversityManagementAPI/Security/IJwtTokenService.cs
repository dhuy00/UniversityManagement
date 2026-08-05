using System.Security.Claims;

public interface IJwtTokenService
{
    string CreateToken(
        string sessionId,
        AuthenticatedUser user,
        DateTimeOffset expiresAt);

    string CreateToken(
        string sessionId,
        AuthenticatedUser user,
        DateTimeOffset expiresAt,
        IEnumerable<Claim>? additionalClaims);
}
