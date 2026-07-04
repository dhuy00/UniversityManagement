using Oracle.ManagedDataAccess.Client;
using System.Data;

public sealed class EnrollmentRepository : IEnrollmentRepository
{
    private readonly IDbConnectionFactory _connectionFactory;

    public EnrollmentRepository(IDbConnectionFactory connectionFactory)
    {
        _connectionFactory = connectionFactory;
    }

    public async Task<IReadOnlyList<EnrollmentDto>> GetAllAsync(
        CancellationToken cancellationToken)
    {
        return await QueryAsync(null, cancellationToken);
    }

    public async Task<IReadOnlyList<EnrollmentDto>> GetByCoursePlanAsync(
        string courseId,
        int semester,
        int academicYear,
        string programId,
        CancellationToken cancellationToken)
    {
        var filter = new CoursePlanFilter(
            courseId,
            semester,
            academicYear,
            programId);
        return await QueryAsync(filter, cancellationToken);
    }

    private async Task<IReadOnlyList<EnrollmentDto>> QueryAsync(
        CoursePlanFilter? filter,
        CancellationToken cancellationToken)
    {
        var enrollments = new List<EnrollmentDto>();

        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);

        await using var command = connection.CreateCommand();
        command.BindByName = true;
        command.CommandType = CommandType.Text;
        var filterSql = filter is null
            ? string.Empty
            : """
              WHERE e.COURSE_ID = :course_id
                AND e.SEMESTER = :semester
                AND e.ACADEMIC_YEAR = :academic_year
                AND e.PROGRAM_ID = :program_id
              """;
        command.CommandText = $"""
            SELECT
                e.STUDENT_ID,
                s.FULL_NAME AS STUDENT_NAME,
                e.LECTURER_ID,
                e.COURSE_ID,
                c.COURSE_NAME,
                e.SEMESTER,
                e.ACADEMIC_YEAR,
                e.PROGRAM_ID,
                e.PRACTICE_SCORE,
                e.PROCESS_SCORE,
                e.FINAL_EXAM_SCORE,
                e.FINAL_SCORE
            FROM UNIVERSITY_APP.ENROLLMENTS e
            JOIN UNIVERSITY_APP.STUDENTS s
              ON s.STUDENT_ID = e.STUDENT_ID
            JOIN UNIVERSITY_APP.COURSES c
              ON c.COURSE_ID = e.COURSE_ID
            {filterSql}
            ORDER BY
                e.ACADEMIC_YEAR DESC,
                e.SEMESTER,
                e.COURSE_ID,
                e.STUDENT_ID
            """;

        if (filter is not null)
        {
            command.Parameters.Add("course_id", OracleDbType.Varchar2).Value =
                filter.CourseId;
            command.Parameters.Add("semester", OracleDbType.Int32).Value =
                filter.Semester;
            command.Parameters.Add("academic_year", OracleDbType.Int32).Value =
                filter.AcademicYear;
            command.Parameters.Add("program_id", OracleDbType.Varchar2).Value =
                filter.ProgramId;
        }

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            enrollments.Add(new EnrollmentDto
            {
                StudentId = reader.GetString(reader.GetOrdinal("STUDENT_ID")),
                StudentName = reader.GetString(reader.GetOrdinal("STUDENT_NAME")),
                LecturerId = reader.GetString(reader.GetOrdinal("LECTURER_ID")),
                CourseId = reader.GetString(reader.GetOrdinal("COURSE_ID")),
                CourseName = reader.GetString(reader.GetOrdinal("COURSE_NAME")),
                Semester = ReadInt32(reader, "SEMESTER"),
                AcademicYear = ReadInt32(reader, "ACADEMIC_YEAR"),
                ProgramId = reader.GetString(reader.GetOrdinal("PROGRAM_ID")),
                PracticeScore = ReadNullableDecimal(reader, "PRACTICE_SCORE"),
                ProcessScore = ReadNullableDecimal(reader, "PROCESS_SCORE"),
                FinalExamScore = ReadNullableDecimal(reader, "FINAL_EXAM_SCORE"),
                FinalScore = ReadNullableDecimal(reader, "FINAL_SCORE")
            });
        }

        return enrollments;
    }

    private sealed record CoursePlanFilter(
        string CourseId,
        int Semester,
        int AcademicYear,
        string ProgramId);

    private static int ReadInt32(IDataRecord reader, string name)
    {
        return Convert.ToInt32(reader.GetDecimal(reader.GetOrdinal(name)));
    }

    private static decimal? ReadNullableDecimal(IDataRecord reader, string name)
    {
        var ordinal = reader.GetOrdinal(name);
        return reader.IsDBNull(ordinal) ? null : reader.GetDecimal(ordinal);
    }
}
