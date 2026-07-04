using Microsoft.AspNetCore.DataProtection;
using System.Collections.Concurrent;
using System.Security.Cryptography;

public sealed class OracleSessionStore : IOracleSessionStore
{
    private sealed record Session(string ProtectedConnectionString, DateTimeOffset ExpiresAt);

    private readonly ConcurrentDictionary<string, Session> _sessions = new();
    private readonly IDataProtector _protector;

    public OracleSessionStore(IDataProtectionProvider dataProtectionProvider)
    {
        _protector = dataProtectionProvider.CreateProtector(
            "UniversityManagementAPI.OracleSession.v1");
    }

    public string Create(string connectionString, DateTimeOffset expiresAt)
    {
        var sessionId = Convert.ToHexString(RandomNumberGenerator.GetBytes(32));
        _sessions[sessionId] = new Session(_protector.Protect(connectionString), expiresAt);
        return sessionId;
    }

    public bool TryGetConnectionString(string sessionId, out string connectionString)
    {
        connectionString = string.Empty;

        if (!_sessions.TryGetValue(sessionId, out var session))
        {
            return false;
        }

        if (session.ExpiresAt <= DateTimeOffset.UtcNow)
        {
            _sessions.TryRemove(sessionId, out _);
            return false;
        }

        try
        {
            connectionString = _protector.Unprotect(session.ProtectedConnectionString);
            return true;
        }
        catch
        {
            _sessions.TryRemove(sessionId, out _);
            return false;
        }
    }

    public bool IsActive(string sessionId)
    {
        return TryGetConnectionString(sessionId, out _);
    }

    public void Remove(string sessionId)
    {
        _sessions.TryRemove(sessionId, out _);
    }
}
