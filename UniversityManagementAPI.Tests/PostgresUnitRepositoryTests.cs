using Npgsql;
using UniversityManagementAPI.Repositories;

namespace UniversityManagementAPI.Tests;

/// <summary>
/// Unit tests for PostgresUnitRepository behavior that doesn't require a database.
/// Integration tests that require a real PostgreSQL connection live in
/// PostgresUnitRepositoryIntegrationTests.cs.
/// </summary>
public sealed class PostgresUnitRepositoryTests
{
    [Fact]
    public async Task GetAllAsync_ThrowsWhenTransactionNotInitialized()
    {
        var mockTx = new UninitializedTransaction();
        var repo = new PostgresUnitRepository(mockTx);

        await Assert.ThrowsAsync<InvalidOperationException>(() =>
            repo.GetAllAsync(CancellationToken.None));
    }

    [Fact]
    public async Task CreateAsync_ThrowsWhenTransactionNotInitialized()
    {
        var mockTx = new UninitializedTransaction();
        var repo = new PostgresUnitRepository(mockTx);

        var request = new CreateUnitRequest
        {
            UnitId = "CS",
            UnitName = "Computer Science"
        };

        await Assert.ThrowsAsync<InvalidOperationException>(() =>
            repo.CreateAsync(request, CancellationToken.None));
    }

    [Fact]
    public async Task UpdateAsync_ThrowsWhenTransactionNotInitialized()
    {
        var mockTx = new UninitializedTransaction();
        var repo = new PostgresUnitRepository(mockTx);

        var request = new UpdateUnitRequest
        {
            UnitName = "Computer Science",
            HeadStaffId = "GV001"
        };

        await Assert.ThrowsAsync<InvalidOperationException>(() =>
            repo.UpdateAsync("CS", request, CancellationToken.None));
    }

    private sealed class UninitializedTransaction : IPostgresRequestTransaction
    {
        public NpgsqlConnection Connection =>
            throw new InvalidOperationException("Transaction not initialized");
        public NpgsqlTransaction Transaction =>
            throw new InvalidOperationException("Transaction not initialized");
        public long UserId => 1;

        public Task InitializeAsync(CancellationToken cancellationToken = default) =>
            Task.CompletedTask;

        public Task CommitAsync(CancellationToken cancellationToken = default) =>
            Task.CompletedTask;

        public ValueTask DisposeAsync() => ValueTask.CompletedTask;
    }
}

/// <summary>
/// Integration tests for PostgresUnitRepository.
/// These tests require a running PostgreSQL instance and environment variables
/// to be set:
/// - POSTGRES_UNIT_TEST_CONNECTION_STRING
/// - POSTGRES_UNIT_TEST_USER_ID (must be a user permitted to read units)
/// </summary>
[Collection(PostgresIntegrationCollection.Name)]
public sealed class PostgresUnitRepositoryIntegrationTests
{
    [Fact]
    public async Task GetAllAsync_ReturnsUnits()
    {
        var settings = UnitIntegrationSettings.TryLoad();
        if (settings is null)
        {
            return;
        }

        await using var source = NpgsqlDataSource.Create(settings.ConnectionString);
        await using var connection = await source.OpenConnectionAsync();
        await using var transaction = await connection.BeginTransactionAsync();

        await using (var cmd = new NpgsqlCommand(
            "SELECT university.set_security_context($1)",
            connection,
            transaction))
        {
            cmd.Parameters.AddWithValue(settings.UserId);
            await cmd.ExecuteNonQueryAsync();
        }

        var tx = new SimpleTransaction(connection, transaction);
        var repo = new PostgresUnitRepository(tx);
        var units = await repo.GetAllAsync();

        Assert.NotNull(units);
    }

    [Fact]
    public async Task UpdateAsync_ReturnsFalseForUnknownUnit()
    {
        var settings = UnitIntegrationSettings.TryLoad();
        if (settings is null)
        {
            return;
        }

        await using var source = NpgsqlDataSource.Create(settings.ConnectionString);
        await using var connection = await source.OpenConnectionAsync();
        await using var transaction = await connection.BeginTransactionAsync();

        await using (var cmd = new NpgsqlCommand(
            "SELECT university.set_security_context($1)",
            connection,
            transaction))
        {
            cmd.Parameters.AddWithValue(settings.UserId);
            await cmd.ExecuteNonQueryAsync();
        }

        var tx = new SimpleTransaction(connection, transaction);
        var repo = new PostgresUnitRepository(tx);

        var request = new UpdateUnitRequest
        {
            UnitName = "Unknown Unit",
            HeadStaffId = null
        };

        var result = await repo.UpdateAsync($"UNKNOWN_{Guid.NewGuid():N}", request);

        Assert.False(result);
        await transaction.RollbackAsync();
    }

    private sealed record UnitIntegrationSettings(
        string ConnectionString,
        long UserId)
    {
        public static UnitIntegrationSettings? TryLoad()
        {
            var connectionString = Environment.GetEnvironmentVariable(
                "POSTGRES_UNIT_TEST_CONNECTION_STRING");
            var userIdStr = Environment.GetEnvironmentVariable(
                "POSTGRES_UNIT_TEST_USER_ID");

            if (string.IsNullOrWhiteSpace(connectionString) ||
                !long.TryParse(userIdStr, out var userId))
            {
                return null;
            }

            return new UnitIntegrationSettings(connectionString, userId);
        }
    }

    private sealed class SimpleTransaction : IPostgresRequestTransaction
    {
        private readonly NpgsqlConnection _connection;
        private readonly NpgsqlTransaction _transaction;

        public SimpleTransaction(NpgsqlConnection connection, NpgsqlTransaction transaction)
        {
            _connection = connection;
            _transaction = transaction;
        }

        public NpgsqlConnection Connection => _connection;
        public NpgsqlTransaction Transaction => _transaction;
        public long UserId => 1;

        public Task InitializeAsync(CancellationToken cancellationToken = default) =>
            Task.CompletedTask;

        public Task CommitAsync(CancellationToken cancellationToken = default) =>
            Task.CompletedTask;

        public ValueTask DisposeAsync() => ValueTask.CompletedTask;
    }
}