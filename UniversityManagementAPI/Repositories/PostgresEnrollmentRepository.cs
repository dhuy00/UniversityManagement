using Npgsql;
using NpgsqlTypes;
using UniversityManagementAPI.Repositories.Interfaces;

namespace UniversityManagementAPI.Repositories;

public sealed class PostgresEnrollmentRepository : IPostgresEnrollmentRepository
{
    private readonly IPostgresRequestTransaction _transaction;

    public PostgresEnrollmentRepository(IPostgresRequestTransaction transaction)
    {
        _transaction = transaction;
    }

    public async Task<IReadOnlyList<EnrollmentDto>> GetAllAsync(
        CancellationToken cancellationToken = default)
    {
        return await QueryAsync(filter: null, cancellationToken);
    }

    public async Task<IReadOnlyList<EnrollmentDto>> GetByCoursePlanAsync(
        string courseId,
        int semester,
        int academicYear,
        string programId,
        CancellationToken cancellationToken = default)
    {
        var filter = new CoursePlanFilter(
            courseId,
            semester,
            academicYear,
            programId);
        return await QueryAsync(filter, cancellationToken);
    }

    public async Task<bool> UpdateScoresAsync(
        UpdateEnrollmentScoresRequest request,
        CancellationToken cancellationToken = default)
    {
        const string sql = """
            UPDATE university.enrollments
            SET
                practice_score = $1,
                process_score = $2,
                final_exam_score = $3,
                final_score = $4
            WHERE student_id = $5
              AND lecturer_id = $6
              AND course_id = $7
              AND semester = $8
              AND academic_year = $9
              AND program_id = $10
            """;

        await using var command = new NpgsqlCommand(sql, _transaction.Connection, _transaction.Transaction);
        AddNullableDecimal(command, request.PracticeScore);
        AddNullableDecimal(command, request.ProcessScore);
        AddNullableDecimal(command, request.FinalExamScore);
        AddNullableDecimal(command, request.FinalScore);
        command.Parameters.AddWithValue(request.StudentId.Trim().ToUpperInvariant());
        command.Parameters.AddWithValue(request.LecturerId.Trim().ToUpperInvariant());
        command.Parameters.AddWithValue(request.CourseId.Trim().ToUpperInvariant());
        command.Parameters.AddWithValue(request.Semester);
        command.Parameters.AddWithValue(request.AcademicYear);
        command.Parameters.AddWithValue(request.ProgramId.Trim().ToUpperInvariant());

        var updated = await command.ExecuteNonQueryAsync(cancellationToken);
        return updated == 1;
    }

    public async Task<IReadOnlyList<RegistrationOptionDto>>
        GetRegistrationOptionsAsync(CancellationToken cancellationToken = default)
    {
        const string sql = """
            SELECT
                ta.lecturer_id,
                ta.course_id,
                c.course_name,
                ta.semester,
                ta.academic_year,
                ta.program_id,
                cp.start_date,
                CASE
                    WHEN CURRENT_DATE
                         BETWEEN cp.start_date
                             AND cp.start_date + INTERVAL '14 days'
                    THEN TRUE
                    ELSE FALSE
                END AS registration_open
            FROM university.teaching_assignments ta
            JOIN university.course_plans cp
              ON cp.course_id = ta.course_id
             AND cp.semester = ta.semester
             AND cp.academic_year = ta.academic_year
             AND cp.program_id = ta.program_id
            JOIN university.courses c
              ON c.course_id = ta.course_id
            ORDER BY
                ta.academic_year,
                ta.semester,
                ta.course_id,
                ta.lecturer_id
            """;

        await using var command = new NpgsqlCommand(sql, _transaction.Connection, _transaction.Transaction);

        var options = new List<RegistrationOptionDto>();
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            options.Add(new RegistrationOptionDto
            {
                LecturerId = reader.GetString(reader.GetOrdinal("lecturer_id")),
                CourseId = reader.GetString(reader.GetOrdinal("course_id")),
                CourseName = reader.GetString(reader.GetOrdinal("course_name")),
                Semester = reader.GetInt16(reader.GetOrdinal("semester")),
                AcademicYear = reader.GetInt16(reader.GetOrdinal("academic_year")),
                ProgramId = reader.GetString(reader.GetOrdinal("program_id")),
                StartDate = reader.GetDateTime(reader.GetOrdinal("start_date")),
                RegistrationOpen = reader.GetBoolean(reader.GetOrdinal("registration_open"))
            });
        }

        return options;
    }

    public async Task CreateAsync(
        MaintainEnrollmentRequest request,
        CancellationToken cancellationToken = default)
    {
        const string sql = """
            INSERT INTO university.enrollments (
                student_id,
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
                $5,
                $6
            )
            """;

        await using var command = new NpgsqlCommand(sql, _transaction.Connection, _transaction.Transaction);
        AddEnrollmentKeyParameters(command, request);

        await command.ExecuteNonQueryAsync(cancellationToken);
    }

    public async Task<bool> DeleteAsync(
        MaintainEnrollmentRequest request,
        CancellationToken cancellationToken = default)
    {
        const string sql = """
            DELETE FROM university.enrollments
            WHERE student_id = $1
              AND lecturer_id = $2
              AND course_id = $3
              AND semester = $4
              AND academic_year = $5
              AND program_id = $6
            """;

        await using var command = new NpgsqlCommand(sql, _transaction.Connection, _transaction.Transaction);
        AddEnrollmentKeyParameters(command, request);

        var deleted = await command.ExecuteNonQueryAsync(cancellationToken);
        return deleted == 1;
    }

    private async Task<IReadOnlyList<EnrollmentDto>> QueryAsync(
        CoursePlanFilter? filter,
        CancellationToken cancellationToken)
    {
        var filterSql = filter is null
            ? string.Empty
            : """
              WHERE e.course_id = $1
                AND e.semester = $2
                AND e.academic_year = $3
                AND e.program_id = $4
              """;
        var sql = $"""
            SELECT
                e.student_id,
                s.full_name AS student_name,
                e.lecturer_id,
                e.course_id,
                c.course_name,
                e.semester,
                e.academic_year,
                e.program_id,
                e.practice_score,
                e.process_score,
                e.final_exam_score,
                e.final_score
            FROM university.enrollments e
            JOIN university.students s
              ON s.student_id = e.student_id
            JOIN university.courses c
              ON c.course_id = e.course_id
            {filterSql}
            ORDER BY
                e.academic_year DESC,
                e.semester,
                e.course_id,
                e.student_id
            """;

        await using var command = new NpgsqlCommand(sql, _transaction.Connection, _transaction.Transaction);
        if (filter is not null)
        {
            command.Parameters.AddWithValue(filter.CourseId.Trim().ToUpperInvariant());
            command.Parameters.AddWithValue(filter.Semester);
            command.Parameters.AddWithValue(filter.AcademicYear);
            command.Parameters.AddWithValue(filter.ProgramId.Trim().ToUpperInvariant());
        }

        var enrollments = new List<EnrollmentDto>();
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            enrollments.Add(new EnrollmentDto
            {
                StudentId = reader.GetString(reader.GetOrdinal("student_id")),
                StudentName = reader.GetString(reader.GetOrdinal("student_name")),
                LecturerId = reader.GetString(reader.GetOrdinal("lecturer_id")),
                CourseId = reader.GetString(reader.GetOrdinal("course_id")),
                CourseName = reader.GetString(reader.GetOrdinal("course_name")),
                Semester = reader.GetInt16(reader.GetOrdinal("semester")),
                AcademicYear = reader.GetInt16(reader.GetOrdinal("academic_year")),
                ProgramId = reader.GetString(reader.GetOrdinal("program_id")),
                PracticeScore = ReadNullableDecimal(reader, "practice_score"),
                ProcessScore = ReadNullableDecimal(reader, "process_score"),
                FinalExamScore = ReadNullableDecimal(reader, "final_exam_score"),
                FinalScore = ReadNullableDecimal(reader, "final_score")
            });
        }

        return enrollments;
    }

    private sealed record CoursePlanFilter(
        string CourseId,
        int Semester,
        int AcademicYear,
        string ProgramId);

    private static decimal? ReadNullableDecimal(NpgsqlDataReader reader, string name)
    {
        var ordinal = reader.GetOrdinal(name);
        return reader.IsDBNull(ordinal) ? null : reader.GetDecimal(ordinal);
    }

    private static void AddNullableDecimal(
        NpgsqlCommand command,
        decimal? value)
    {
        var parameter = command.Parameters.Add(string.Empty, NpgsqlDbType.Numeric);
        parameter.Value = value.HasValue ? value.Value : DBNull.Value;
    }

    private static void AddEnrollmentKeyParameters(
        NpgsqlCommand command,
        MaintainEnrollmentRequest request)
    {
        command.Parameters.AddWithValue(request.StudentId.Trim().ToUpperInvariant());
        command.Parameters.AddWithValue(request.LecturerId.Trim().ToUpperInvariant());
        command.Parameters.AddWithValue(request.CourseId.Trim().ToUpperInvariant());
        command.Parameters.AddWithValue(request.Semester);
        command.Parameters.AddWithValue(request.AcademicYear);
        command.Parameters.AddWithValue(request.ProgramId.Trim().ToUpperInvariant());
    }
}
