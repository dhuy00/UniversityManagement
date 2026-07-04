public interface IOracleSessionStore
{
    string Create(string connectionString, DateTimeOffset expiresAt);
    bool TryGetConnectionString(string sessionId, out string connectionString);
    bool IsActive(string sessionId);
    void Remove(string sessionId);
}
