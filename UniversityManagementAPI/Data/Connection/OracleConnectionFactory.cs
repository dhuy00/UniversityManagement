using Oracle.ManagedDataAccess.Client;
using System.Security.Authentication;

public class OracleConnectionFactory : IDbConnectionFactory
{
    private readonly IHttpContextAccessor _httpContextAccessor;
    private readonly IOracleSessionStore _sessionStore;

    public OracleConnectionFactory(
        IHttpContextAccessor httpContextAccessor,
        IOracleSessionStore sessionStore)
    {
        _httpContextAccessor = httpContextAccessor;
        _sessionStore = sessionStore;
    }

    public OracleConnection CreateConnection()
    {
        var sessionId = _httpContextAccessor.HttpContext?.User.FindFirst("sid")?.Value;

        if (string.IsNullOrWhiteSpace(sessionId) ||
            !_sessionStore.TryGetConnectionString(sessionId, out var connectionString))
        {
            throw new AuthenticationException("The authenticated Oracle session is unavailable or expired.");
        }

        return new OracleConnection(connectionString);
    }
}
