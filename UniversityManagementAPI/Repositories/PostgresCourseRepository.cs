using Npgsql;
using UniversityManagementAPI.Repositories.Interfaces;

namespace UniversityManagementAPI.Repositories;

public sealed class PostgresCourseRepository : IPostgresCourseRepository
{
    private readonly IPostgresRequestTransaction _transaction;

    public PostgresCourseRepository(IPostgresRequestTransaction transaction)
    {
        _transaction = transaction;
    }

    public async Task<IReadOnlyList<CourseDto>> GetAllAsync(
        CancellationToken cancellationToken = default)
    {
        const string sql = """
            SELECT
                course_id,
                course_name,
                credits,
                theory_periods,
                practice_periods,
                max_students,
                unit_id
            FROM university.courses
            ORDER BY course_id
            """;

        await using var command = new NpgsqlCommand(sql, _transaction.Connection, _transaction.Transaction);

        var courses = new List<CourseDto>();
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            courses.Add(new CourseDto
            {
                CourseId = reader.GetString(reader.GetOrdinal("course_id")),
                CourseName = reader.GetString(reader.GetOrdinal("course_name")),
                Credits = reader.GetInt16(reader.GetOrdinal("credits")),
                TheoryPeriods = reader.GetInt16(reader.GetOrdinal("theory_periods")),
                PracticePeriods = reader.GetInt16(reader.GetOrdinal("practice_periods")),
                MaxStudents = reader.GetInt16(reader.GetOrdinal("max_students")),
                UnitId = reader.GetString(reader.GetOrdinal("unit_id"))
            });
        }

        return courses;
    }

    public async Task CreateAsync(
        SaveCourseRequest request,
        CancellationToken cancellationToken = default)
    {
        const string sql = """
            INSERT INTO university.courses (
                course_id,
                course_name,
                credits,
                theory_periods,
                practice_periods,
                max_students,
                unit_id
            ) VALUES (
                $1,
                $2,
                $3,
                $4,
                $5,
                $6,
                $7
            )
            """;

        await using var command = new NpgsqlCommand(sql, _transaction.Connection, _transaction.Transaction);
        AddCourseParameters(command, request);

        await command.ExecuteNonQueryAsync(cancellationToken);
    }

    public async Task<bool> UpdateAsync(
        string courseId,
        SaveCourseRequest request,
        CancellationToken cancellationToken = default)
    {
        const string sql = """
            UPDATE university.courses
            SET
                course_name = $2,
                credits = $3,
                theory_periods = $4,
                practice_periods = $5,
                max_students = $6,
                unit_id = $7
            WHERE course_id = $1
            """;

        await using var command = new NpgsqlCommand(sql, _transaction.Connection, _transaction.Transaction);
        AddCourseParameters(command, request, courseId);

        var updated = await command.ExecuteNonQueryAsync(cancellationToken);
        return updated == 1;
    }

    private static void AddCourseParameters(
        NpgsqlCommand command,
        SaveCourseRequest request,
        string? courseId = null)
    {
        command.Parameters.AddWithValue((courseId ?? request.CourseId).Trim().ToUpperInvariant());
        command.Parameters.AddWithValue(request.CourseName.Trim());
        command.Parameters.AddWithValue(request.Credits);
        command.Parameters.AddWithValue(request.TheoryPeriods);
        command.Parameters.AddWithValue(request.PracticePeriods);
        command.Parameters.AddWithValue(request.MaxStudents);
        command.Parameters.AddWithValue(request.UnitId.Trim().ToUpperInvariant());
    }
}
