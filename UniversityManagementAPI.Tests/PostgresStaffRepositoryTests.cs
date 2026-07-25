using Npgsql;
using UniversityManagementAPI.Repositories;

namespace UniversityManagementAPI.Tests;

/// <summary>
/// Unit tests for PostgresStaffRepository behavior that doesn't require a database.
/// Integration tests that require a real PostgreSQL connection live in
/// PostgresStaffRepositoryIntegrationTests.cs.
/// </summary>
public sealed class PostgresStaffRepositoryTests
{
    [Fact]
    public async Task GetAllAsync_ThrowsWhenTransactionNotInitialized()
    {
        var mockTx = new UninitializedTransaction();
        var repo = new PostgresStaffRepository(mockTx);

        await Assert.ThrowsAsync<InvalidOperationException>(() =>
            repo.GetAllAsync(CancellationToken.None));
    }

    [Fact]
    public async Task CreateAsync_ThrowsWhenTransactionNotInitialized()
    {
        var mockTx = new UninitializedTransaction();
        var repo = new PostgresStaffRepository(mockTx);

        var request = new CreateStaffRequest
        {
            StaffId = "GV001",
            FullName = "Test Staff",
            Gender = "MALE",
            DateOfBirth = new DateTime(1980, 1, 1),
            Allowance = 1000m,
            RoleCode = "LECTURER",
            UnitId = "CS",
            OracleUsername = "gv001",
            CampusId = "CAMPUS_1"
        };

        await Assert.ThrowsAsync<InvalidOperationException>(() =>
            repo.CreateAsync(request, CancellationToken.None));
    }

    [Fact]
    public async Task UpdateAsync_ThrowsWhenTransactionNotInitialized()
    {
        var mockTx = new UninitializedTransaction();
        var repo = new PostgresStaffRepository(mockTx);

        var request = new UpdateStaffRequest
        {
            FullName = "Test Staff",
            Gender = "MALE",
            DateOfBirth = new DateTime(1980, 1, 1),
            Allowance = 1000m,
            RoleCode = "LECTURER",
            UnitId = "CS",
            CampusId = "CAMPUS_1"
        };

        await Assert.ThrowsAsync<InvalidOperationException>(() =>
            repo.UpdateAsync("GV001", request, CancellationToken.None));
    }

    [Fact]
    public async Task DeleteAsync_ThrowsWhenTransactionNotInitialized()
    {
        var mockTx = new UninitializedTransaction();
        var repo = new PostgresStaffRepository(mockTx);

        await Assert.ThrowsAsync<InvalidOperationException>(() =>
            repo.DeleteAsync("GV001", CancellationToken.None));
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
/// Integration tests for PostgresStaffRepository.
/// These tests require a running PostgreSQL instance and environment variables
/// to be set:
/// - POSTGRES_STAFF_TEST_CONNECTION_STRING
/// - POSTGRES_STAFF_TEST_USER_ID (must be a user permitted to read staff)
/// </summary>
[Collection(PostgresIntegrationCollection.Name)]
public sealed class PostgresStaffRepositoryIntegrationTests
{
    [Fact]
    public async Task GetAllAsync_ReturnsStaff()
    {
        var settings = StaffIntegrationSettings.TryLoad();
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
        var repo = new PostgresStaffRepository(tx);
        var staff = await repo.GetAllAsync();

        Assert.NotNull(staff);
    }

    [Fact]
    public async Task DeleteAsync_ReturnsFalseForUnknownStaff()
    {
        var settings = StaffIntegrationSettings.TryLoad();
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
        var repo = new PostgresStaffRepository(tx);

        var result = await repo.DeleteAsync($"UNKNOWN_{Guid.NewGuid():N}");

        Assert.False(result);
        await transaction.RollbackAsync();
    }

    private sealed record StaffIntegrationSettings(
        string ConnectionString,
        long UserId)
    {
        public static StaffIntegrationSettings? TryLoad()
        {
            var connectionString = Environment.GetEnvironmentVariable(
                "POSTGRES_STAFF_TEST_CONNECTION_STRING");
            var userIdStr = Environment.GetEnvironmentVariable(
                "POSTGRES_STAFF_TEST_USER_ID");

            if (string.IsNullOrWhiteSpace(connectionString) ||
                !long.TryParse(userIdStr, out var userId))
            {
                return null;
            }

            return new StaffIntegrationSettings(connectionString, userId);
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