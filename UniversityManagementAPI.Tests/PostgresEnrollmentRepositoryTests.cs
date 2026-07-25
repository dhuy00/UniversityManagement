using Npgsql;
using UniversityManagementAPI.Repositories;

namespace UniversityManagementAPI.Tests;

/// <summary>
/// Unit tests for PostgresEnrollmentRepository behavior that doesn't require a database.
/// Integration tests that require a real PostgreSQL connection live in
/// PostgresEnrollmentRepositoryIntegrationTests.cs.
/// </summary>
public sealed class PostgresEnrollmentRepositoryTests
{
    [Fact]
    public async Task GetAllAsync_ThrowsWhenTransactionNotInitialized()
    {
        var mockTx = new UninitializedTransaction();
        var repo = new PostgresEnrollmentRepository(mockTx);

        await Assert.ThrowsAsync<InvalidOperationException>(() =>
            repo.GetAllAsync(CancellationToken.None));
    }

    [Fact]
    public async Task GetByCoursePlanAsync_ThrowsWhenTransactionNotInitialized()
    {
        var mockTx = new UninitializedTransaction();
        var repo = new PostgresEnrollmentRepository(mockTx);

        await Assert.ThrowsAsync<InvalidOperationException>(() =>
            repo.GetByCoursePlanAsync("CS101", 1, 2026, "REGULAR", CancellationToken.None));
    }

    [Fact]
    public async Task UpdateScoresAsync_ThrowsWhenTransactionNotInitialized()
    {
        var mockTx = new UninitializedTransaction();
        var repo = new PostgresEnrollmentRepository(mockTx);

        var request = new UpdateEnrollmentScoresRequest
        {
            StudentId = "SV001",
            LecturerId = "GV001",
            CourseId = "CS101",
            Semester = 1,
            AcademicYear = 2026,
            ProgramId = "REGULAR",
            PracticeScore = 8.0m,
            ProcessScore = 7.5m,
            FinalExamScore = 9.0m,
            FinalScore = 8.5m
        };

        await Assert.ThrowsAsync<InvalidOperationException>(() =>
            repo.UpdateScoresAsync(request, CancellationToken.None));
    }

    [Fact]
    public async Task GetRegistrationOptionsAsync_ThrowsWhenTransactionNotInitialized()
    {
        var mockTx = new UninitializedTransaction();
        var repo = new PostgresEnrollmentRepository(mockTx);

        await Assert.ThrowsAsync<InvalidOperationException>(() =>
            repo.GetRegistrationOptionsAsync(CancellationToken.None));
    }

    [Fact]
    public async Task CreateAsync_ThrowsWhenTransactionNotInitialized()
    {
        var mockTx = new UninitializedTransaction();
        var repo = new PostgresEnrollmentRepository(mockTx);

        var request = new MaintainEnrollmentRequest
        {
            StudentId = "SV001",
            LecturerId = "GV001",
            CourseId = "CS101",
            Semester = 1,
            AcademicYear = 2026,
            ProgramId = "REGULAR"
        };

        await Assert.ThrowsAsync<InvalidOperationException>(() =>
            repo.CreateAsync(request, CancellationToken.None));
    }

    [Fact]
    public async Task DeleteAsync_ThrowsWhenTransactionNotInitialized()
    {
        var mockTx = new UninitializedTransaction();
        var repo = new PostgresEnrollmentRepository(mockTx);

        var request = new MaintainEnrollmentRequest
        {
            StudentId = "SV001",
            LecturerId = "GV001",
            CourseId = "CS101",
            Semester = 1,
            AcademicYear = 2026,
            ProgramId = "REGULAR"
        };

        await Assert.ThrowsAsync<InvalidOperationException>(() =>
            repo.DeleteAsync(request, CancellationToken.None));
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
/// Integration tests for PostgresEnrollmentRepository.
/// These tests require a running PostgreSQL instance and environment variables
/// to be set:
/// - POSTGRES_ENROLLMENT_TEST_CONNECTION_STRING
/// - POSTGRES_ENROLLMENT_TEST_USER_ID (must be a user permitted to read enrollments)
/// </summary>
[Collection(PostgresIntegrationCollection.Name)]
public sealed class PostgresEnrollmentRepositoryIntegrationTests
{
    [Fact]
    public async Task GetAllAsync_ReturnsEnrollments()
    {
        var settings = EnrollmentIntegrationSettings.TryLoad();
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
        var repo = new PostgresEnrollmentRepository(tx);
        var enrollments = await repo.GetAllAsync();

        Assert.NotNull(enrollments);
    }

    [Fact]
    public async Task GetRegistrationOptionsAsync_ReturnsOptions()
    {
        var settings = EnrollmentIntegrationSettings.TryLoad();
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
        var repo = new PostgresEnrollmentRepository(tx);
        var options = await repo.GetRegistrationOptionsAsync();

        Assert.NotNull(options);
    }

    [Fact]
    public async Task DeleteAsync_ReturnsFalseForUnknownEnrollment()
    {
        var settings = EnrollmentIntegrationSettings.TryLoad();
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
        var repo = new PostgresEnrollmentRepository(tx);

        var request = new MaintainEnrollmentRequest
        {
            StudentId = $"UNKNOWN_{Guid.NewGuid():N}",
            LecturerId = $"UNKNOWN_{Guid.NewGuid():N}",
            CourseId = $"UNKNOWN_{Guid.NewGuid():N}",
            Semester = 1,
            AcademicYear = 2099,
            ProgramId = "REGULAR"
        };

        var result = await repo.DeleteAsync(request);

        Assert.False(result);
        await transaction.RollbackAsync();
    }

    private sealed record EnrollmentIntegrationSettings(
        string ConnectionString,
        long UserId)
    {
        public static EnrollmentIntegrationSettings? TryLoad()
        {
            var connectionString = Environment.GetEnvironmentVariable(
                "POSTGRES_ENROLLMENT_TEST_CONNECTION_STRING");
            var userIdStr = Environment.GetEnvironmentVariable(
                "POSTGRES_ENROLLMENT_TEST_USER_ID");

            if (string.IsNullOrWhiteSpace(connectionString) ||
                !long.TryParse(userIdStr, out var userId))
            {
                return null;
            }

            return new EnrollmentIntegrationSettings(connectionString, userId);
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