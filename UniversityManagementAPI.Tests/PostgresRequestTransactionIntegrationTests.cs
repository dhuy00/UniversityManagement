using Npgsql;

[CollectionDefinition(Name, DisableParallelization = true)]
public sealed class PostgresIntegrationCollection
{
    public const string Name = "PostgreSQL integration";
}

[Collection(PostgresIntegrationCollection.Name)]
public sealed class PostgresRequestTransactionIntegrationTests
{
    [Fact]
    public async Task InitializesContextAndClearsItBeforePooledConnectionReuse()
    {
        var settings = IntegrationSettings.TryLoad();
        if (settings is null)
        {
            return;
        }

        var builder = new NpgsqlConnectionStringBuilder(settings.ConnectionString)
        {
            MaxPoolSize = 1,
            MinPoolSize = 1
        };
        await using var dataSource = NpgsqlDataSource.Create(builder.ConnectionString);
        int backendProcessId;

        await using (var request = CreateRequest(dataSource, settings.ActiveUserId))
        {
            await request.InitializeAsync();
            backendProcessId = request.Connection.ProcessID;
            Assert.Equal(settings.ActiveUserId, await ReadCurrentUserIdAsync(request));
            await request.CommitAsync();
        }

        await using var connection = await dataSource.OpenConnectionAsync();
        Assert.Equal(backendProcessId, connection.ProcessID);
        await using var transaction = await connection.BeginTransactionAsync();
        await using var command = new NpgsqlCommand(
            "SELECT university.current_app_user_id()",
            connection,
            transaction);
        Assert.Null(await command.ExecuteScalarAsync());
    }

    [Fact]
    public async Task RejectsInactiveUser()
    {
        var settings = IntegrationSettings.TryLoad();
        if (settings?.InactiveUserId is null)
        {
            return;
        }

        await using var dataSource = NpgsqlDataSource.Create(settings.ConnectionString);
        await using var request = CreateRequest(dataSource, settings.InactiveUserId.Value);

        var exception = await Assert.ThrowsAsync<PostgresException>(
            () => request.InitializeAsync());
        Assert.Equal(PostgresErrorCodes.InvalidAuthorizationSpecification, exception.SqlState);
    }

    [Fact]
    public async Task MissingContextFailsClosedForProtectedRows()
    {
        var settings = IntegrationSettings.TryLoad();
        if (settings is null)
        {
            return;
        }

        await using var dataSource = NpgsqlDataSource.Create(settings.ConnectionString);
        await using var connection = await dataSource.OpenConnectionAsync();
        await using var transaction = await connection.BeginTransactionAsync();
        await using var command = new NpgsqlCommand(
            "SELECT count(*) FROM university.students",
            connection,
            transaction);

        Assert.Equal(0L, await command.ExecuteScalarAsync());
    }

    private static PostgresRequestTransaction CreateRequest(
        NpgsqlDataSource dataSource,
        long userId) => new(dataSource, new FixedAuthenticatedUser(userId));

    private static async Task<long?> ReadCurrentUserIdAsync(
        IPostgresRequestTransaction request)
    {
        await using var command = new NpgsqlCommand(
            "SELECT university.current_app_user_id()",
            request.Connection,
            request.Transaction);
        return (long?)await command.ExecuteScalarAsync();
    }

    private sealed class FixedAuthenticatedUser(long userId) : IAuthenticatedPostgresUser
    {
        public long GetRequiredUserId() => userId;
    }

    private sealed record IntegrationSettings(
        string ConnectionString,
        long ActiveUserId,
        long? InactiveUserId)
    {
        public static IntegrationSettings? TryLoad()
        {
            var connectionString = Environment.GetEnvironmentVariable(
                "POSTGRES_INTEGRATION_CONNECTION_STRING");
            var activeValue = Environment.GetEnvironmentVariable(
                "POSTGRES_TEST_ACTIVE_USER_ID");

            if (string.IsNullOrWhiteSpace(connectionString) ||
                !long.TryParse(activeValue, out var activeUserId) ||
                activeUserId <= 0)
            {
                return null;
            }

            var inactiveValue = Environment.GetEnvironmentVariable(
                "POSTGRES_TEST_INACTIVE_USER_ID");
            long? inactiveUserId = long.TryParse(inactiveValue, out var parsedInactive) &&
                parsedInactive > 0
                    ? parsedInactive
                    : null;
            return new IntegrationSettings(
                connectionString,
                activeUserId,
                inactiveUserId);
        }
    }
}
