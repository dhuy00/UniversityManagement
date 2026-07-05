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

    public async Task<bool> UpdateScoresAsync(
        UpdateEnrollmentScoresRequest request,
        CancellationToken cancellationToken)
    {
        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);
        await using var transaction = connection.BeginTransaction();

        await using var command = connection.CreateCommand();
        command.Transaction = transaction;
        command.BindByName = true;
        command.CommandType = CommandType.Text;
        command.CommandText = """
            UPDATE UNIVERSITY_APP.ENROLLMENTS
            SET
                PRACTICE_SCORE = :practice_score,
                PROCESS_SCORE = :process_score,
                FINAL_EXAM_SCORE = :final_exam_score,
                FINAL_SCORE = :final_score
            WHERE STUDENT_ID = :student_id
              AND LECTURER_ID = :lecturer_id
              AND COURSE_ID = :course_id
              AND SEMESTER = :semester
              AND ACADEMIC_YEAR = :academic_year
              AND PROGRAM_ID = :program_id
            """;

        AddNullableDecimal(command, "practice_score", request.PracticeScore);
        AddNullableDecimal(command, "process_score", request.ProcessScore);
        AddNullableDecimal(command, "final_exam_score", request.FinalExamScore);
        AddNullableDecimal(command, "final_score", request.FinalScore);
        command.Parameters.Add("student_id", OracleDbType.Varchar2).Value =
            request.StudentId;
        command.Parameters.Add("lecturer_id", OracleDbType.Varchar2).Value =
            request.LecturerId;
        command.Parameters.Add("course_id", OracleDbType.Varchar2).Value =
            request.CourseId;
        command.Parameters.Add("semester", OracleDbType.Int32).Value =
            request.Semester;
        command.Parameters.Add("academic_year", OracleDbType.Int32).Value =
            request.AcademicYear;
        command.Parameters.Add("program_id", OracleDbType.Varchar2).Value =
            request.ProgramId;

        var updated = await command.ExecuteNonQueryAsync(cancellationToken) == 1;
        if (updated)
        {
            await transaction.CommitAsync(cancellationToken);
        }
        else
        {
            await transaction.RollbackAsync(cancellationToken);
        }

        return updated;
    }

    public async Task<IReadOnlyList<RegistrationOptionDto>>
        GetRegistrationOptionsAsync(CancellationToken cancellationToken)
    {
        var options = new List<RegistrationOptionDto>();

        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);
        await using var command = connection.CreateCommand();
        command.CommandType = CommandType.Text;
        command.CommandText = """
            SELECT
                ta.LECTURER_ID,
                ta.COURSE_ID,
                c.COURSE_NAME,
                ta.SEMESTER,
                ta.ACADEMIC_YEAR,
                ta.PROGRAM_ID,
                cp.START_DATE,
                CASE
                    WHEN TRUNC(SYSDATE)
                         BETWEEN TRUNC(cp.START_DATE)
                             AND TRUNC(cp.START_DATE) + 14
                    THEN 1
                    ELSE 0
                END AS REGISTRATION_OPEN
            FROM UNIVERSITY_APP.TEACHING_ASSIGNMENTS ta
            JOIN UNIVERSITY_APP.COURSE_PLANS cp
              ON cp.COURSE_ID = ta.COURSE_ID
             AND cp.SEMESTER = ta.SEMESTER
             AND cp.ACADEMIC_YEAR = ta.ACADEMIC_YEAR
             AND cp.PROGRAM_ID = ta.PROGRAM_ID
            JOIN UNIVERSITY_APP.COURSES c
              ON c.COURSE_ID = ta.COURSE_ID
            ORDER BY
                ta.ACADEMIC_YEAR,
                ta.SEMESTER,
                ta.COURSE_ID,
                ta.LECTURER_ID
            """;

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            options.Add(new RegistrationOptionDto
            {
                LecturerId = reader.GetString(reader.GetOrdinal("LECTURER_ID")),
                CourseId = reader.GetString(reader.GetOrdinal("COURSE_ID")),
                CourseName = reader.GetString(reader.GetOrdinal("COURSE_NAME")),
                Semester = ReadInt32(reader, "SEMESTER"),
                AcademicYear = ReadInt32(reader, "ACADEMIC_YEAR"),
                ProgramId = reader.GetString(reader.GetOrdinal("PROGRAM_ID")),
                StartDate = reader.GetDateTime(reader.GetOrdinal("START_DATE")),
                RegistrationOpen =
                    ReadInt32(reader, "REGISTRATION_OPEN") == 1
            });
        }

        return options;
    }

    public async Task CreateAsync(
        MaintainEnrollmentRequest request,
        CancellationToken cancellationToken)
    {
        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);
        await using var transaction = connection.BeginTransaction();

        await using var command = connection.CreateCommand();
        command.Transaction = transaction;
        command.BindByName = true;
        command.CommandType = CommandType.Text;
        command.CommandText = """
            INSERT INTO UNIVERSITY_APP.ENROLLMENTS (
                STUDENT_ID,
                LECTURER_ID,
                COURSE_ID,
                SEMESTER,
                ACADEMIC_YEAR,
                PROGRAM_ID
            ) VALUES (
                :student_id,
                :lecturer_id,
                :course_id,
                :semester,
                :academic_year,
                :program_id
            )
            """;
        AddEnrollmentKeyParameters(command, request);

        await command.ExecuteNonQueryAsync(cancellationToken);
        await transaction.CommitAsync(cancellationToken);
    }

    public async Task<bool> DeleteAsync(
        MaintainEnrollmentRequest request,
        CancellationToken cancellationToken)
    {
        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);
        await using var transaction = connection.BeginTransaction();

        await using var command = connection.CreateCommand();
        command.Transaction = transaction;
        command.BindByName = true;
        command.CommandType = CommandType.Text;
        command.CommandText = """
            DELETE FROM UNIVERSITY_APP.ENROLLMENTS
            WHERE STUDENT_ID = :student_id
              AND LECTURER_ID = :lecturer_id
              AND COURSE_ID = :course_id
              AND SEMESTER = :semester
              AND ACADEMIC_YEAR = :academic_year
              AND PROGRAM_ID = :program_id
            """;
        AddEnrollmentKeyParameters(command, request);

        var deleted = await command.ExecuteNonQueryAsync(cancellationToken) == 1;
        if (deleted)
        {
            await transaction.CommitAsync(cancellationToken);
        }
        else
        {
            await transaction.RollbackAsync(cancellationToken);
        }

        return deleted;
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

    private static void AddNullableDecimal(
        OracleCommand command,
        string name,
        decimal? value)
    {
        command.Parameters.Add(name, OracleDbType.Decimal).Value =
            value.HasValue ? value.Value : DBNull.Value;
    }

    private static void AddEnrollmentKeyParameters(
        OracleCommand command,
        MaintainEnrollmentRequest request)
    {
        command.Parameters.Add("student_id", OracleDbType.Varchar2).Value =
            request.StudentId.Trim().ToUpperInvariant();
        command.Parameters.Add("lecturer_id", OracleDbType.Varchar2).Value =
            request.LecturerId.Trim().ToUpperInvariant();
        command.Parameters.Add("course_id", OracleDbType.Varchar2).Value =
            request.CourseId.Trim().ToUpperInvariant();
        command.Parameters.Add("semester", OracleDbType.Int32).Value =
            request.Semester;
        command.Parameters.Add("academic_year", OracleDbType.Int32).Value =
            request.AcademicYear;
        command.Parameters.Add("program_id", OracleDbType.Varchar2).Value =
            request.ProgramId.Trim().ToUpperInvariant();
    }
}
