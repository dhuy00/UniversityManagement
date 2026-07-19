using System.Globalization;
using System.Security.Authentication;

public sealed class HttpContextPostgresUser : IAuthenticatedPostgresUser
{
    public const string UserIdClaim = "app_user_id";

    private readonly IHttpContextAccessor _httpContextAccessor;

    public HttpContextPostgresUser(IHttpContextAccessor httpContextAccessor)
    {
        _httpContextAccessor = httpContextAccessor;
    }

    public long GetRequiredUserId()
    {
        var principal = _httpContextAccessor.HttpContext?.User;
        var claimValue = principal?.FindFirst(UserIdClaim)?.Value;

        if (principal?.Identity?.IsAuthenticated != true ||
            !long.TryParse(
                claimValue,
                NumberStyles.None,
                CultureInfo.InvariantCulture,
                out var userId) ||
            userId <= 0)
        {
            throw new AuthenticationException(
                "The authenticated PostgreSQL application user is unavailable.");
        }

        return userId;
    }
}
