using Npgsql;
using UniversityManagementAPI.Repositories;

namespace UniversityManagementAPI.Tests;

/// <summary>
/// Unit tests for PostgresTeachingAssignmentRepository behavior that doesn't require a database.
/// Integration tests that require a real PostgreSQL connection live in
/// PostgresTeachingAssignmentRepositoryIntegrationTests.cs.
/// </summary>
public sealed class PostgresTeachingAssignmentRepositoryTests
{
    [Fact]
    public async Task GetAllAsync_ThrowsWhenTransactionNotInitialized()
    {
        var mockTx = new UninitializedTransaction();
        var repo = new PostgresTeachingAssignmentRepository(mockTx);

        await Assert.ThrowsAsync<InvalidOperationException>(() =>
            repo.GetAllAsync(CancellationToken.None));
    }

    [Fact]
    public async Task CreateAsync_ThrowsWhenTransactionNotInitialized()
    {
        var mockTx = new UninitializedTransaction();
        var repo = new PostgresTeachingAssignmentRepository(mockTx);

        var request = new SaveTeachingAssignmentRequest
        {
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
    public async Task UpdateAsync_ThrowsWhenTransactionNotInitialized()
    {
        var mockTx = new UninitializedTransaction();
        var repo = new PostgresTeachingAssignmentRepository(mockTx);

        var original = new TeachingAssignmentDto
        {
            LecturerId = "GV001",
            CourseId = "CS101",
            Semester = 1,
            AcademicYear = 2026,
            ProgramId = "REGULAR"
        };
        var request = new SaveTeachingAssignmentRequest
        {
            LecturerId = "GV002",
            CourseId = "CS101",
            Semester = 1,
            AcademicYear = 2026,
            ProgramId = "REGULAR"
        };

        await Assert.ThrowsAsync<InvalidOperationException>(() =>
            repo.UpdateAsync(original, request, CancellationToken.None));
    }

    [Fact]
    public async Task DeleteAsync_ThrowsWhenTransactionNotInitialized()
    {
        var mockTx = new UninitializedTransaction();
        var repo = new PostgresTeachingAssignmentRepository(mockTx);

        var assignment = new TeachingAssignmentDto
        {
            LecturerId = "GV001",
            CourseId = "CS101",
            Semester = 1,
            AcademicYear = 2026,
            ProgramId = "REGULAR"
        };

        await Assert.ThrowsAsync<InvalidOperationException>(() =>
            repo.DeleteAsync(assignment, CancellationToken.None));
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
/// Integration tests for PostgresTeachingAssignmentRepository.
/// These tests require a running PostgreSQL instance and environment variables
/// to be set:
/// - POSTGRES_TEACHING_ASSIGNMENT_TEST_CONNECTION_STRING
/// - POSTGRES_TEACHING_ASSIGNMENT_TEST_USER_ID (must be a user permitted to read assignments)
/// </summary>
[Collection(PostgresIntegrationCollection.Name)]
public sealed class PostgresTeachingAssignmentRepositoryIntegrationTests
{
    [Fact]
    public async Task GetAllAsync_ReturnsAssignments()
    {
        var settings = TeachingAssignmentIntegrationSettings.TryLoad();
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
        var repo = new PostgresTeachingAssignmentRepository(tx);
        var assignments = await repo.GetAllAsync();

        Assert.NotNull(assignments);
    }

    [Fact]
    public async Task DeleteAsync_ReturnsFalseForUnknownAssignment()
    {
        var settings = TeachingAssignmentIntegrationSettings.TryLoad();
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
        var repo = new PostgresTeachingAssignmentRepository(tx);

        var assignment = new TeachingAssignmentDto
        {
            LecturerId = $"UNKNOWN_{Guid.NewGuid():N}",
            CourseId = $"UNKNOWN_{Guid.NewGuid():N}",
            Semester = 1,
            AcademicYear = 2099,
            ProgramId = "REGULAR"
        };

        var result = await repo.DeleteAsync(assignment);

        Assert.False(result);
        await transaction.RollbackAsync();
    }

    private sealed record TeachingAssignmentIntegrationSettings(
        string ConnectionString,
        long UserId)
    {
        public static TeachingAssignmentIntegrationSettings? TryLoad()
        {
            var connectionString = Environment.GetEnvironmentVariable(
                "POSTGRES_TEACHING_ASSIGNMENT_TEST_CONNECTION_STRING");
            var userIdStr = Environment.GetEnvironmentVariable(
                "POSTGRES_TEACHING_ASSIGNMENT_TEST_USER_ID");

            if (string.IsNullOrWhiteSpace(connectionString) ||
                !long.TryParse(userIdStr, out var userId))
            {
                return null;
            }

            return new TeachingAssignmentIntegrationSettings(connectionString, userId);
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