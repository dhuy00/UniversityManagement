using Npgsql;
using UniversityManagementAPI.Repositories;

namespace UniversityManagementAPI.Tests;

/// <summary>
/// Unit tests for PostgresStudentRepository behavior that doesn't require a database.
/// Integration tests that require a real PostgreSQL connection live in
/// PostgresStudentRepositoryIntegrationTests.cs.
/// </summary>
public sealed class PostgresStudentRepositoryTests
{
    [Fact]
    public async Task GetPageAsync_ThrowsWhenTransactionNotInitialized()
    {
        var mockTx = new UninitializedTransaction();
        var repo = new PostgresStudentRepository(mockTx);

        await Assert.ThrowsAsync<InvalidOperationException>(() =>
            repo.GetPageAsync(1, 10, null, CancellationToken.None));
    }

    [Fact]
    public async Task CreateAsync_ThrowsWhenTransactionNotInitialized()
    {
        var mockTx = new UninitializedTransaction();
        var repo = new PostgresStudentRepository(mockTx);

        var request = new CreateStudentRequest
        {
            StudentId = "SV001",
            FullName = "Test Student",
            Gender = "MALE",
            DateOfBirth = new DateTime(2000, 1, 1),
            ProgramId = "REGULAR",
            MajorId = "CS",
            AccumulatedCredits = 0,
            CumulativeGpa = 0m,
            OracleUsername = "sv001",
            CampusId = "CAMPUS_1"
        };

        await Assert.ThrowsAsync<InvalidOperationException>(() =>
            repo.CreateAsync(request, CancellationToken.None));
    }

    [Fact]
    public async Task UpdateAsync_ThrowsWhenTransactionNotInitialized()
    {
        var mockTx = new UninitializedTransaction();
        var repo = new PostgresStudentRepository(mockTx);

        var request = new UpdateStudentRequest
        {
            FullName = "Test Student",
            Gender = "MALE",
            DateOfBirth = new DateTime(2000, 1, 1),
            ProgramId = "REGULAR",
            MajorId = "CS",
            AccumulatedCredits = 0,
            CumulativeGpa = 0m,
            CampusId = "CAMPUS_1"
        };

        await Assert.ThrowsAsync<InvalidOperationException>(() =>
            repo.UpdateAsync("SV001", request, CancellationToken.None));
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
/// Integration tests for PostgresStudentRepository.
/// These tests require a running PostgreSQL instance and environment variables
/// to be set:
/// - POSTGRES_STUDENT_TEST_CONNECTION_STRING
/// - POSTGRES_STUDENT_TEST_USER_ID (must be a user permitted to read students)
/// </summary>
[Collection(PostgresIntegrationCollection.Name)]
public sealed class PostgresStudentRepositoryIntegrationTests
{
    [Fact]
    public async Task GetPageAsync_ReturnsPage()
    {
        var settings = StudentIntegrationSettings.TryLoad();
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
        var repo = new PostgresStudentRepository(tx);
        var page = await repo.GetPageAsync(1, 10, null);

        Assert.NotNull(page);
        Assert.True(page.TotalItems >= 0);
    }

    [Fact]
    public async Task UpdateAsync_ReturnsFalseForUnknownStudent()
    {
        var settings = StudentIntegrationSettings.TryLoad();
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
        var repo = new PostgresStudentRepository(tx);

        var request = new UpdateStudentRequest
        {
            FullName = "Unknown Student",
            Gender = "MALE",
            DateOfBirth = new DateTime(2000, 1, 1),
            ProgramId = "REGULAR",
            MajorId = "CS",
            AccumulatedCredits = 0,
            CumulativeGpa = 0m,
            CampusId = "CAMPUS_1"
        };

        var result = await repo.UpdateAsync($"UNKNOWN_{Guid.NewGuid():N}", request);

        Assert.False(result);
        await transaction.RollbackAsync();
    }

    private sealed record StudentIntegrationSettings(
        string ConnectionString,
        long UserId)
    {
        public static StudentIntegrationSettings? TryLoad()
        {
            var connectionString = Environment.GetEnvironmentVariable(
                "POSTGRES_STUDENT_TEST_CONNECTION_STRING");
            var userIdStr = Environment.GetEnvironmentVariable(
                "POSTGRES_STUDENT_TEST_USER_ID");

            if (string.IsNullOrWhiteSpace(connectionString) ||
                !long.TryParse(userIdStr, out var userId))
            {
                return null;
            }

            return new StudentIntegrationSettings(connectionString, userId);
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