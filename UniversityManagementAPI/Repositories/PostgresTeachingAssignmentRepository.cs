using Npgsql;
using UniversityManagementAPI.Repositories.Interfaces;

namespace UniversityManagementAPI.Repositories;

public sealed class PostgresTeachingAssignmentRepository
    : IPostgresTeachingAssignmentRepository
{
    private readonly IPostgresRequestTransaction _transaction;

    public PostgresTeachingAssignmentRepository(IPostgresRequestTransaction transaction)
    {
        _transaction = transaction;
    }

    public async Task<IReadOnlyList<TeachingAssignmentDto>> GetAllAsync(
        CancellationToken cancellationToken = default)
    {
        const string sql = """
            SELECT
                ta.lecturer_id,
                ta.course_id,
                c.course_name,
                c.unit_id,
                ta.semester,
                ta.academic_year,
                ta.program_id
            FROM university.teaching_assignments ta
            JOIN university.courses c
              ON c.course_id = ta.course_id
            ORDER BY
                ta.academic_year DESC,
                ta.semester,
                ta.lecturer_id,
                ta.course_id,
                ta.program_id
            """;

        await using var command = new NpgsqlCommand(sql, _transaction.Connection, _transaction.Transaction);

        var assignments = new List<TeachingAssignmentDto>();
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            assignments.Add(new TeachingAssignmentDto
            {
                LecturerId = reader.GetString(reader.GetOrdinal("lecturer_id")),
                CourseId = reader.GetString(reader.GetOrdinal("course_id")),
                CourseName = reader.GetString(reader.GetOrdinal("course_name")),
                UnitId = reader.GetString(reader.GetOrdinal("unit_id")),
                Semester = reader.GetInt16(reader.GetOrdinal("semester")),
                AcademicYear = reader.GetInt16(reader.GetOrdinal("academic_year")),
                ProgramId = reader.GetString(reader.GetOrdinal("program_id"))
            });
        }

        return assignments;
    }

    public async Task CreateAsync(
        SaveTeachingAssignmentRequest request,
        CancellationToken cancellationToken = default)
    {
        const string sql = """
            INSERT INTO university.teaching_assignments (
                lecturer_id,
                course_id,
                semester,
                academic_year,
                program_id
            ) VALUES (
                $1,
                $2,
                $3,
                $4,
                $5
            )
            """;

        await using var command = new NpgsqlCommand(sql, _transaction.Connection, _transaction.Transaction);
        AddAssignmentParameters(command, request);

        await command.ExecuteNonQueryAsync(cancellationToken);
    }

    public async Task<bool> UpdateAsync(
        TeachingAssignmentDto original,
        SaveTeachingAssignmentRequest request,
        CancellationToken cancellationToken = default)
    {
        const string sql = """
            UPDATE university.teaching_assignments
            SET
                lecturer_id = $1,
                course_id = $2,
                semester = $3,
                academic_year = $4,
                program_id = $5
            WHERE lecturer_id = $6
              AND course_id = $7
              AND semester = $8
              AND academic_year = $9
              AND program_id = $10
            """;

        await using var command = new NpgsqlCommand(sql, _transaction.Connection, _transaction.Transaction);
        AddAssignmentParameters(command, request);
        AddOriginalParameters(command, original);

        var updated = await command.ExecuteNonQueryAsync(cancellationToken);
        return updated == 1;
    }

    public async Task<bool> DeleteAsync(
        TeachingAssignmentDto assignment,
        CancellationToken cancellationToken = default)
    {
        const string sql = """
            DELETE FROM university.teaching_assignments
            WHERE lecturer_id = $1
              AND course_id = $2
              AND semester = $3
              AND academic_year = $4
              AND program_id = $5
            """;

        await using var command = new NpgsqlCommand(sql, _transaction.Connection, _transaction.Transaction);
        AddOriginalParameters(command, assignment);

        var deleted = await command.ExecuteNonQueryAsync(cancellationToken);
        return deleted == 1;
    }

    private static void AddAssignmentParameters(
        NpgsqlCommand command,
        SaveTeachingAssignmentRequest request)
    {
        command.Parameters.AddWithValue(request.LecturerId.Trim().ToUpperInvariant());
        command.Parameters.AddWithValue(request.CourseId.Trim().ToUpperInvariant());
        command.Parameters.AddWithValue(request.Semester);
        command.Parameters.AddWithValue(request.AcademicYear);
        command.Parameters.AddWithValue(request.ProgramId.Trim().ToUpperInvariant());
    }

    private static void AddOriginalParameters(
        NpgsqlCommand command,
        TeachingAssignmentDto assignment)
    {
        command.Parameters.AddWithValue(assignment.LecturerId);
        command.Parameters.AddWithValue(assignment.CourseId);
        command.Parameters.AddWithValue(assignment.Semester);
        command.Parameters.AddWithValue(assignment.AcademicYear);
        command.Parameters.AddWithValue(assignment.ProgramId);
    }
}
