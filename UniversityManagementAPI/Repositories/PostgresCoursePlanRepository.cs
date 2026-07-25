using Npgsql;
using UniversityManagementAPI.Repositories.Interfaces;

namespace UniversityManagementAPI.Repositories;

public sealed class PostgresCoursePlanRepository : IPostgresCoursePlanRepository
{
    private readonly IPostgresRequestTransaction _transaction;

    public PostgresCoursePlanRepository(IPostgresRequestTransaction transaction)
    {
        _transaction = transaction;
    }

    public async Task<IReadOnlyList<CoursePlanDto>> GetAllAsync(
        CancellationToken cancellationToken = default)
    {
        const string sql = """
            SELECT
                cp.course_id,
                c.course_name,
                c.unit_id,
                cp.semester,
                cp.academic_year,
                cp.program_id,
                cp.start_date,
                CASE
                    WHEN CURRENT_DATE
                         BETWEEN cp.start_date
                             AND cp.start_date + INTERVAL '14 days'
                    THEN TRUE
                    ELSE FALSE
                END AS registration_open
            FROM university.course_plans cp
            JOIN university.courses c
              ON c.course_id = cp.course_id
            ORDER BY
                cp.academic_year DESC,
                cp.semester,
                cp.program_id,
                cp.course_id
            """;

        await using var command = new NpgsqlCommand(sql, _transaction.Connection, _transaction.Transaction);

        var plans = new List<CoursePlanDto>();
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            plans.Add(new CoursePlanDto
            {
                CourseId = reader.GetString(reader.GetOrdinal("course_id")),
                CourseName = reader.GetString(reader.GetOrdinal("course_name")),
                UnitId = reader.GetString(reader.GetOrdinal("unit_id")),
                Semester = reader.GetInt16(reader.GetOrdinal("semester")),
                AcademicYear = reader.GetInt16(reader.GetOrdinal("academic_year")),
                ProgramId = reader.GetString(reader.GetOrdinal("program_id")),
                StartDate = reader.GetDateTime(reader.GetOrdinal("start_date")),
                RegistrationOpen = reader.GetBoolean(reader.GetOrdinal("registration_open"))
            });
        }

        return plans;
    }

    public async Task CreateAsync(
        SaveCoursePlanRequest request,
        CancellationToken cancellationToken = default)
    {
        const string sql = """
            INSERT INTO university.course_plans (
                course_id,
                semester,
                academic_year,
                program_id,
                start_date
            ) VALUES (
                $1,
                $2,
                $3,
                $4,
                $5
            )
            """;

        await using var command = new NpgsqlCommand(sql, _transaction.Connection, _transaction.Transaction);
        AddPlanParameters(command, request);

        await command.ExecuteNonQueryAsync(cancellationToken);
    }

    public async Task<bool> UpdateAsync(
        string originalCourseId,
        int originalSemester,
        int originalAcademicYear,
        string originalProgramId,
        SaveCoursePlanRequest request,
        CancellationToken cancellationToken = default)
    {
        const string sql = """
            UPDATE university.course_plans
            SET
                course_id = $5,
                semester = $6,
                academic_year = $7,
                program_id = $8,
                start_date = $9
            WHERE course_id = $1
              AND semester = $2
              AND academic_year = $3
              AND program_id = $4
            """;

        await using var command = new NpgsqlCommand(sql, _transaction.Connection, _transaction.Transaction);
        command.Parameters.AddWithValue(originalCourseId.ToUpperInvariant());
        command.Parameters.AddWithValue(originalSemester);
        command.Parameters.AddWithValue(originalAcademicYear);
        command.Parameters.AddWithValue(originalProgramId.ToUpperInvariant());
        AddPlanParameters(command, request);

        var updated = await command.ExecuteNonQueryAsync(cancellationToken);
        return updated == 1;
    }

    private static void AddPlanParameters(
        NpgsqlCommand command,
        SaveCoursePlanRequest request)
    {
        command.Parameters.AddWithValue(request.CourseId.Trim().ToUpperInvariant());
        command.Parameters.AddWithValue(request.Semester);
        command.Parameters.AddWithValue(request.AcademicYear);
        command.Parameters.AddWithValue(request.ProgramId.Trim().ToUpperInvariant());
        command.Parameters.AddWithValue(request.StartDate);
    }
}
