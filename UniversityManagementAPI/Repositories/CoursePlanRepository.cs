using Oracle.ManagedDataAccess.Client;
using System.Data;

public sealed class CoursePlanRepository : ICoursePlanRepository
{
    private readonly IDbConnectionFactory _connectionFactory;

    public CoursePlanRepository(IDbConnectionFactory connectionFactory)
    {
        _connectionFactory = connectionFactory;
    }

    public async Task<IReadOnlyList<CoursePlanDto>> GetAllAsync(
        CancellationToken cancellationToken)
    {
        var plans = new List<CoursePlanDto>();

        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);

        await using var command = connection.CreateCommand();
        command.CommandType = CommandType.Text;
        command.CommandText = """
            SELECT
                cp.COURSE_ID,
                c.COURSE_NAME,
                c.UNIT_ID,
                cp.SEMESTER,
                cp.ACADEMIC_YEAR,
                cp.PROGRAM_ID,
                cp.START_DATE,
                CASE
                    WHEN TRUNC(SYSDATE)
                         BETWEEN TRUNC(cp.START_DATE)
                             AND TRUNC(cp.START_DATE) + 14
                    THEN 1
                    ELSE 0
                END AS REGISTRATION_OPEN
            FROM UNIVERSITY_APP.COURSE_PLANS cp
            JOIN UNIVERSITY_APP.COURSES c
              ON c.COURSE_ID = cp.COURSE_ID
            ORDER BY
                cp.ACADEMIC_YEAR DESC,
                cp.SEMESTER,
                cp.PROGRAM_ID,
                cp.COURSE_ID
            """;

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            plans.Add(new CoursePlanDto
            {
                CourseId = reader.GetString(reader.GetOrdinal("COURSE_ID")),
                CourseName = reader.GetString(reader.GetOrdinal("COURSE_NAME")),
                UnitId = reader.GetString(reader.GetOrdinal("UNIT_ID")),
                Semester = ReadInt32(reader, "SEMESTER"),
                AcademicYear = ReadInt32(reader, "ACADEMIC_YEAR"),
                ProgramId = reader.GetString(reader.GetOrdinal("PROGRAM_ID")),
                StartDate = reader.GetDateTime(reader.GetOrdinal("START_DATE")),
                RegistrationOpen =
                    ReadInt32(reader, "REGISTRATION_OPEN") == 1
            });
        }

        return plans;
    }

    public async Task CreateAsync(
        SaveCoursePlanRequest request,
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
            INSERT INTO UNIVERSITY_APP.COURSE_PLANS (
                COURSE_ID,
                SEMESTER,
                ACADEMIC_YEAR,
                PROGRAM_ID,
                START_DATE
            ) VALUES (
                :course_id,
                :semester,
                :academic_year,
                :program_id,
                :start_date
            )
            """;
        AddPlanParameters(command, request);

        await command.ExecuteNonQueryAsync(cancellationToken);
        await transaction.CommitAsync(cancellationToken);
    }

    public async Task<bool> UpdateAsync(
        string originalCourseId,
        int originalSemester,
        int originalAcademicYear,
        string originalProgramId,
        SaveCoursePlanRequest request,
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
            UPDATE UNIVERSITY_APP.COURSE_PLANS
            SET
                COURSE_ID = :course_id,
                SEMESTER = :semester,
                ACADEMIC_YEAR = :academic_year,
                PROGRAM_ID = :program_id,
                START_DATE = :start_date
            WHERE COURSE_ID = :original_course_id
              AND SEMESTER = :original_semester
              AND ACADEMIC_YEAR = :original_academic_year
              AND PROGRAM_ID = :original_program_id
            """;
        AddPlanParameters(command, request);
        command.Parameters.Add(
            "original_course_id",
            OracleDbType.Varchar2).Value = originalCourseId.ToUpperInvariant();
        command.Parameters.Add(
            "original_semester",
            OracleDbType.Int32).Value = originalSemester;
        command.Parameters.Add(
            "original_academic_year",
            OracleDbType.Int32).Value = originalAcademicYear;
        command.Parameters.Add(
            "original_program_id",
            OracleDbType.Varchar2).Value = originalProgramId.ToUpperInvariant();

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

    private static int ReadInt32(IDataRecord reader, string name)
    {
        return Convert.ToInt32(reader.GetDecimal(reader.GetOrdinal(name)));
    }

    private static void AddPlanParameters(
        OracleCommand command,
        SaveCoursePlanRequest request)
    {
        command.Parameters.Add("course_id", OracleDbType.Varchar2).Value =
            request.CourseId.Trim().ToUpperInvariant();
        command.Parameters.Add("semester", OracleDbType.Int32).Value =
            request.Semester;
        command.Parameters.Add("academic_year", OracleDbType.Int32).Value =
            request.AcademicYear;
        command.Parameters.Add("program_id", OracleDbType.Varchar2).Value =
            request.ProgramId.Trim().ToUpperInvariant();
        command.Parameters.Add("start_date", OracleDbType.Date).Value =
            request.StartDate;
    }
}
