using Npgsql;
using UniversityManagementAPI.Repositories;

namespace UniversityManagementAPI.Tests;

/// <summary>
/// Unit tests for PostgresCourseRepository behavior that doesn't require a database.
/// Integration tests that require a real PostgreSQL connection live in
/// PostgresCourseRepositoryIntegrationTests.cs.
/// </summary>
public sealed class PostgresCourseRepositoryTests
{
    [Fact]
    public async Task GetAllAsync_ThrowsWhenTransactionNotInitialized()
    {
        var mockTx = new UninitializedTransaction();
        var repo = new PostgresCourseRepository(mockTx);

        await Assert.ThrowsAsync<InvalidOperationException>(() =>
            repo.GetAllAsync(CancellationToken.None));
    }

    [Fact]
    public async Task CreateAsync_ThrowsWhenTransactionNotInitialized()
    {
        var mockTx = new UninitializedTransaction();
        var repo = new PostgresCourseRepository(mockTx);

        var request = new SaveCourseRequest
        {
            CourseId = "CS101",
            CourseName = "Intro to CS",
            Credits = 3,
            TheoryPeriods = 30,
            PracticePeriods = 15,
            MaxStudents = 60,
            UnitId = "CS"
        };

        await Assert.ThrowsAsync<InvalidOperationException>(() =>
            repo.CreateAsync(request, CancellationToken.None));
    }

    [Fact]
    public async Task UpdateAsync_ThrowsWhenTransactionNotInitialized()
    {
        var mockTx = new UninitializedTransaction();
        var repo = new PostgresCourseRepository(mockTx);

        var request = new SaveCourseRequest
        {
            CourseId = "CS101",
            CourseName = "Intro to CS",
            Credits = 3,
            TheoryPeriods = 30,
            PracticePeriods = 15,
            MaxStudents = 60,
            UnitId = "CS"
        };

        await Assert.ThrowsAsync<InvalidOperationException>(() =>
            repo.UpdateAsync("CS101", request, CancellationToken.None));
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
/// Integration tests for PostgresCourseRepository.
/// These tests require a running PostgreSQL instance and environment variables
/// to be set:
/// - POSTGRES_COURSE_TEST_CONNECTION_STRING
/// - POSTGRES_COURSE_TEST_USER_ID (must be a user permitted to read courses)
/// </summary>
[Collection(PostgresIntegrationCollection.Name)]
public sealed class PostgresCourseRepositoryIntegrationTests
{
    [Fact]
    public async Task GetAllAsync_ReturnsCourses()
    {
        var settings = CourseIntegrationSettings.TryLoad();
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
        var repo = new PostgresCourseRepository(tx);
        var courses = await repo.GetAllAsync();

        Assert.NotNull(courses);
        // The catalog must be readable; this assertion holds even when empty.
        Assert.IsType<List<CourseDto>>(courses as List<CourseDto>);
    }

    [Fact]
    public async Task UpdateAsync_ReturnsFalseForUnknownCourse()
    {
        var settings = CourseIntegrationSettings.TryLoad();
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
        var repo = new PostgresCourseRepository(tx);

        var unknownId = $"UNKNOWN_{Guid.NewGuid():N}";
        var request = new SaveCourseRequest
        {
            CourseId = unknownId,
            CourseName = "Unknown Course",
            Credits = 3,
            TheoryPeriods = 30,
            PracticePeriods = 0,
            MaxStudents = 60,
            UnitId = "CS"
        };

        var result = await repo.UpdateAsync(unknownId, request);

        Assert.False(result);
        await transaction.RollbackAsync();
    }

    private sealed record CourseIntegrationSettings(
        string ConnectionString,
        long UserId)
    {
        public static CourseIntegrationSettings? TryLoad()
        {
            var connectionString = Environment.GetEnvironmentVariable(
                "POSTGRES_COURSE_TEST_CONNECTION_STRING");
            var userIdStr = Environment.GetEnvironmentVariable(
                "POSTGRES_COURSE_TEST_USER_ID");

            if (string.IsNullOrWhiteSpace(connectionString) ||
                !long.TryParse(userIdStr, out var userId))
            {
                return null;
            }

            return new CourseIntegrationSettings(connectionString, userId);
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
