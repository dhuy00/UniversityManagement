using Npgsql;
using UniversityManagementAPI.Repositories;

namespace UniversityManagementAPI.Tests;

/// <summary>
/// Unit tests for PostgresCoursePlanRepository behavior that doesn't require a database.
/// Integration tests that require a real PostgreSQL connection live in
/// PostgresCoursePlanRepositoryIntegrationTests.cs.
/// </summary>
public sealed class PostgresCoursePlanRepositoryTests
{
    [Fact]
    public async Task GetAllAsync_ThrowsWhenTransactionNotInitialized()
    {
        var mockTx = new UninitializedTransaction();
        var repo = new PostgresCoursePlanRepository(mockTx);

        await Assert.ThrowsAsync<InvalidOperationException>(() =>
            repo.GetAllAsync(CancellationToken.None));
    }

    [Fact]
    public async Task CreateAsync_ThrowsWhenTransactionNotInitialized()
    {
        var mockTx = new UninitializedTransaction();
        var repo = new PostgresCoursePlanRepository(mockTx);

        var request = new SaveCoursePlanRequest
        {
            CourseId = "CS101",
            Semester = 1,
            AcademicYear = 2026,
            ProgramId = "REGULAR",
            StartDate = new DateTime(2026, 9, 1)
        };

        await Assert.ThrowsAsync<InvalidOperationException>(() =>
            repo.CreateAsync(request, CancellationToken.None));
    }

    [Fact]
    public async Task UpdateAsync_ThrowsWhenTransactionNotInitialized()
    {
        var mockTx = new UninitializedTransaction();
        var repo = new PostgresCoursePlanRepository(mockTx);

        var request = new SaveCoursePlanRequest
        {
            CourseId = "CS101",
            Semester = 1,
            AcademicYear = 2026,
            ProgramId = "REGULAR",
            StartDate = new DateTime(2026, 9, 1)
        };

        await Assert.ThrowsAsync<InvalidOperationException>(() =>
            repo.UpdateAsync("CS101", 1, 2026, "REGULAR", request, CancellationToken.None));
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
/// Integration tests for PostgresCoursePlanRepository.
/// These tests require a running PostgreSQL instance and environment variables
/// to be set:
/// - POSTGRES_COURSE_PLAN_TEST_CONNECTION_STRING
/// - POSTGRES_COURSE_PLAN_TEST_USER_ID (must be a user permitted to read course plans)
/// </summary>
[Collection(PostgresIntegrationCollection.Name)]
public sealed class PostgresCoursePlanRepositoryIntegrationTests
{
    [Fact]
    public async Task GetAllAsync_ReturnsCoursePlans()
    {
        var settings = CoursePlanIntegrationSettings.TryLoad();
        if (settings is null)
        {
            return;
        }

        await using var source = NpgsqlDataSource.Create(settings.ConnectionString);
        await using var connection = await source.OpenConnectionAsync();
        await using var transaction = await connection.BeginTransactionAsync();

        // Set security context for authenticated access.
        await using (var cmd = new NpgsqlCommand(
            "SELECT university.set_security_context($1)",
            connection,
            transaction))
        {
            cmd.Parameters.AddWithValue(settings.UserId);
            await cmd.ExecuteNonQueryAsync();
        }

        var tx = new SimpleTransaction(connection, transaction);
        var repo = new PostgresCoursePlanRepository(tx);
        var plans = await repo.GetAllAsync();

        Assert.NotNull(plans);
    }

    [Fact]
    public async Task UpdateAsync_ReturnsFalseForUnknownPlan()
    {
        var settings = CoursePlanIntegrationSettings.TryLoad();
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
        var repo = new PostgresCoursePlanRepository(tx);

        var request = new SaveCoursePlanRequest
        {
            CourseId = $"UNKNOWN_{Guid.NewGuid():N}",
            Semester = 1,
            AcademicYear = 2026,
            ProgramId = "REGULAR",
            StartDate = new DateTime(2026, 9, 1)
        };

        var result = await repo.UpdateAsync(
            request.CourseId,
            request.Semester,
            request.AcademicYear,
            request.ProgramId,
            request);

        Assert.False(result);
        await transaction.RollbackAsync();
    }

    private sealed record CoursePlanIntegrationSettings(
        string ConnectionString,
        long UserId)
    {
        public static CoursePlanIntegrationSettings? TryLoad()
        {
            var connectionString = Environment.GetEnvironmentVariable(
                "POSTGRES_COURSE_PLAN_TEST_CONNECTION_STRING");
            var userIdStr = Environment.GetEnvironmentVariable(
                "POSTGRES_COURSE_PLAN_TEST_USER_ID");

            if (string.IsNullOrWhiteSpace(connectionString) ||
                !long.TryParse(userIdStr, out var userId))
            {
                return null;
            }

            return new CoursePlanIntegrationSettings(connectionString, userId);
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