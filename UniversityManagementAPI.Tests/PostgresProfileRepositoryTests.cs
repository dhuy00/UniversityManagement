using Npgsql;
using UniversityManagementAPI.Repositories;

namespace UniversityManagementAPI.Tests;

/// <summary>
/// Unit tests for PostgresProfileRepository behavior that doesn't require database.
/// Integration tests that require a real PostgreSQL connection live in
/// PostgresProfileRepositoryIntegrationTests.cs.
/// </summary>
public sealed class PostgresProfileRepositoryTests
{
    [Fact]
    public async Task GetStaffProfileAsync_ThrowsWhenTransactionNotInitialized()
    {
        var mockTx = new UninitializedTransaction();
        var repo = new PostgresProfileRepository(mockTx);

        await Assert.ThrowsAsync<InvalidOperationException>(() =>
            repo.GetStaffProfileAsync("ST001"));
    }

    [Fact]
    public async Task GetStudentProfileAsync_ThrowsWhenTransactionNotInitialized()
    {
        var mockTx = new UninitializedTransaction();
        var repo = new PostgresProfileRepository(mockTx);

        await Assert.ThrowsAsync<InvalidOperationException>(() =>
            repo.GetStudentProfileAsync("SV001"));
    }

    [Fact]
    public async Task UpdateContactAsync_ReturnsFalseForUnknownIdentityType()
    {
        var mockTx = new UninitializedTransaction();
        var repo = new PostgresProfileRepository(mockTx);
        var request = new UpdateContactRequest { Phone = "0987654321" };

        // Unknown identity type should return false without accessing the database
        var result = await repo.UpdateContactAsync("UNKNOWN", "ID001", request);

        Assert.False(result);
    }

    [Fact]
    public async Task UpdateContactAsync_ReturnsFalseForNullIdentityType()
    {
        var mockTx = new UninitializedTransaction();
        var repo = new PostgresProfileRepository(mockTx);
        var request = new UpdateContactRequest { Phone = "0987654321" };

        var result = await repo.UpdateContactAsync(null!, "ID001", request);

        Assert.False(result);
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
/// Integration tests for PostgresProfileRepository.
/// These tests require a running PostgreSQL instance and environment variables
/// to be set:
/// - POSTGRES_PROFILE_TEST_CONNECTION_STRING
/// - POSTGRES_PROFILE_TEST_STAFF_ID
/// - POSTGRES_PROFILE_TEST_STUDENT_ID
/// </summary>
[Collection(PostgresIntegrationCollection.Name)]
public sealed class PostgresProfileRepositoryIntegrationTests
{
    [Fact]
    public async Task GetStaffProfileAsync_ReturnsStaffProfile()
    {
        var settings = ProfileIntegrationSettings.TryLoad();
        if (settings?.StaffId is null)
        {
            return;
        }

        await using var source = NpgsqlDataSource.Create(settings.ConnectionString);
        await using var connection = await source.OpenConnectionAsync();
        await using var transaction = await connection.BeginTransactionAsync();

        // Set security context for authenticated access
        await using (var cmd = new NpgsqlCommand(
            "SELECT university.set_security_context($1)",
            connection,
            transaction))
        {
            cmd.Parameters.AddWithValue(settings.UserId);
            await cmd.ExecuteNonQueryAsync();
        }

        var tx = new SimpleTransaction(connection, transaction);
        var repo = new PostgresProfileRepository(tx);
        var result = await repo.GetStaffProfileAsync(settings.StaffId);

        Assert.NotNull(result);
        Assert.Equal(settings.StaffId, result.Id);
        Assert.Equal("STAFF", result.IdentityType);
        Assert.NotNull(result.RoleCode);
        Assert.NotNull(result.UnitId);
        Assert.NotNull(result.CampusId);
    }

    [Fact]
    public async Task GetStudentProfileAsync_ReturnsStudentProfile()
    {
        var settings = ProfileIntegrationSettings.TryLoad();
        if (settings?.StudentId is null)
        {
            return;
        }

        await using var source = NpgsqlDataSource.Create(settings.ConnectionString);
        await using var connection = await source.OpenConnectionAsync();
        await using var transaction = await connection.BeginTransactionAsync();

        // Set security context for authenticated access
        await using (var cmd = new NpgsqlCommand(
            "SELECT university.set_security_context($1)",
            connection,
            transaction))
        {
            cmd.Parameters.AddWithValue(settings.UserId);
            await cmd.ExecuteNonQueryAsync();
        }

        var tx = new SimpleTransaction(connection, transaction);
        var repo = new PostgresProfileRepository(tx);
        var result = await repo.GetStudentProfileAsync(settings.StudentId);

        Assert.NotNull(result);
        Assert.Equal(settings.StudentId, result.Id);
        Assert.Equal("STUDENT", result.IdentityType);
        Assert.NotNull(result.ProgramId);
        Assert.NotNull(result.MajorId);
        Assert.NotNull(result.CampusId);
    }

    [Fact]
    public async Task GetStaffProfileAsync_ReturnsNullForUnknownId()
    {
        var settings = ProfileIntegrationSettings.TryLoad();
        if (settings?.StaffId is null)
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
        var repo = new PostgresProfileRepository(tx);

        var result = await repo.GetStaffProfileAsync($"UNKNOWN_{Guid.NewGuid():N}");

        Assert.Null(result);
    }

    [Fact]
    public async Task UpdateContactAsync_UpdatesStudentContact()
    {
        var settings = ProfileIntegrationSettings.TryLoad();
        if (settings?.StudentId is null || !settings.CanUpdateContact)
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
        var repo = new PostgresProfileRepository(tx);
        var newPhone = $"TEST_{DateTime.UtcNow:yyyyMMddHHmmss}";
        var request = new UpdateContactRequest
        {
            Phone = newPhone,
            Address = "Integration test address"
        };

        var result = await repo.UpdateContactAsync("STUDENT", settings.StudentId, request);

        Assert.True(result);

        // Rollback to not affect the database
        await transaction.RollbackAsync();
    }

    private sealed record ProfileIntegrationSettings(
        string ConnectionString,
        long UserId,
        string? StaffId,
        string? StudentId,
        bool CanUpdateContact)
    {
        public static ProfileIntegrationSettings? TryLoad()
        {
            var connectionString = Environment.GetEnvironmentVariable(
                "POSTGRES_PROFILE_TEST_CONNECTION_STRING");
            var userIdStr = Environment.GetEnvironmentVariable(
                "POSTGRES_PROFILE_TEST_USER_ID");
            var staffId = Environment.GetEnvironmentVariable(
                "POSTGRES_PROFILE_TEST_STAFF_ID");
            var studentId = Environment.GetEnvironmentVariable(
                "POSTGRES_PROFILE_TEST_STUDENT_ID");
            var canUpdateStr = Environment.GetEnvironmentVariable(
                "POSTGRES_PROFILE_TEST_CAN_UPDATE");

            if (string.IsNullOrWhiteSpace(connectionString) ||
                !long.TryParse(userIdStr, out var userId))
            {
                return null;
            }

            return new ProfileIntegrationSettings(
                connectionString,
                userId,
                staffId,
                studentId,
                canUpdateStr?.Equals("true", StringComparison.OrdinalIgnoreCase) == true);
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
