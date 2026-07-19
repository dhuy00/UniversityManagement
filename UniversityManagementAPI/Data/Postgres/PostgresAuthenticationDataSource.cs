using Npgsql;

public sealed class PostgresAuthenticationDataSource : IAsyncDisposable
{
    public PostgresAuthenticationDataSource(IConfiguration configuration)
    {
        var connectionString = configuration.GetConnectionString(
            "PostgreSQLAuthentication");
        if (string.IsNullOrWhiteSpace(connectionString))
        {
            throw new InvalidOperationException(
                "ConnectionStrings:PostgreSQLAuthentication is required.");
        }

        DataSource = NpgsqlDataSource.Create(connectionString);
    }

    public NpgsqlDataSource DataSource { get; }

    public ValueTask DisposeAsync() => DataSource.DisposeAsync();
}
