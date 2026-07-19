using Npgsql;

public sealed class PostgresAuthenticationDataSource : IAsyncDisposable
{
    public PostgresAuthenticationDataSource(IConfiguration configuration)
        : this(GetRequiredConnectionString(configuration))
    {
    }

    public PostgresAuthenticationDataSource(string connectionString)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(connectionString);
        DataSource = NpgsqlDataSource.Create(connectionString);
    }

    public NpgsqlDataSource DataSource { get; }

    public ValueTask DisposeAsync() => DataSource.DisposeAsync();

    private static string GetRequiredConnectionString(IConfiguration configuration)
    {
        var connectionString = configuration.GetConnectionString(
            "PostgreSQLAuthentication");
        if (string.IsNullOrWhiteSpace(connectionString))
        {
            throw new InvalidOperationException(
                "ConnectionStrings:PostgreSQLAuthentication is required.");
        }

        return connectionString;
    }
}
