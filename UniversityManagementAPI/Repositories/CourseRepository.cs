using Oracle.ManagedDataAccess.Client;
using System.Data;

public sealed class CourseRepository : ICourseRepository
{
    private readonly IDbConnectionFactory _connectionFactory;

    public CourseRepository(IDbConnectionFactory connectionFactory)
    {
        _connectionFactory = connectionFactory;
    }

    public async Task<IReadOnlyList<CourseDto>> GetAllAsync(
        CancellationToken cancellationToken)
    {
        var courses = new List<CourseDto>();

        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);

        await using var command = connection.CreateCommand();
        command.CommandType = CommandType.Text;
        command.CommandText = """
            SELECT
                COURSE_ID,
                COURSE_NAME,
                CREDITS,
                THEORY_PERIODS,
                PRACTICE_PERIODS,
                MAX_STUDENTS,
                UNIT_ID
            FROM UNIVERSITY_APP.COURSES
            ORDER BY COURSE_ID
            """;

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            courses.Add(new CourseDto
            {
                CourseId = reader.GetString(reader.GetOrdinal("COURSE_ID")),
                CourseName = reader.GetString(reader.GetOrdinal("COURSE_NAME")),
                Credits = ReadInt32(reader, "CREDITS"),
                TheoryPeriods = ReadInt32(reader, "THEORY_PERIODS"),
                PracticePeriods = ReadInt32(reader, "PRACTICE_PERIODS"),
                MaxStudents = ReadInt32(reader, "MAX_STUDENTS"),
                UnitId = reader.GetString(reader.GetOrdinal("UNIT_ID"))
            });
        }

        return courses;
    }

    public async Task CreateAsync(
        SaveCourseRequest request,
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
            INSERT INTO UNIVERSITY_APP.COURSES (
                COURSE_ID,
                COURSE_NAME,
                CREDITS,
                THEORY_PERIODS,
                PRACTICE_PERIODS,
                MAX_STUDENTS,
                UNIT_ID
            ) VALUES (
                :course_id,
                :course_name,
                :credits,
                :theory_periods,
                :practice_periods,
                :max_students,
                :unit_id
            )
            """;
        AddCourseParameters(command, request);

        await command.ExecuteNonQueryAsync(cancellationToken);
        await transaction.CommitAsync(cancellationToken);
    }

    public async Task<bool> UpdateAsync(
        string courseId,
        SaveCourseRequest request,
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
            UPDATE UNIVERSITY_APP.COURSES
            SET
                COURSE_NAME = :course_name,
                CREDITS = :credits,
                THEORY_PERIODS = :theory_periods,
                PRACTICE_PERIODS = :practice_periods,
                MAX_STUDENTS = :max_students,
                UNIT_ID = :unit_id
            WHERE COURSE_ID = :course_id
            """;
        AddCourseParameters(command, request, courseId);

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

    private static void AddCourseParameters(
        OracleCommand command,
        SaveCourseRequest request,
        string? courseId = null)
    {
        command.Parameters.Add("course_id", OracleDbType.Varchar2).Value =
            (courseId ?? request.CourseId).Trim().ToUpperInvariant();
        command.Parameters.Add("course_name", OracleDbType.Varchar2).Value =
            request.CourseName.Trim();
        command.Parameters.Add("credits", OracleDbType.Int32).Value =
            request.Credits;
        command.Parameters.Add("theory_periods", OracleDbType.Int32).Value =
            request.TheoryPeriods;
        command.Parameters.Add("practice_periods", OracleDbType.Int32).Value =
            request.PracticePeriods;
        command.Parameters.Add("max_students", OracleDbType.Int32).Value =
            request.MaxStudents;
        command.Parameters.Add("unit_id", OracleDbType.Varchar2).Value =
            request.UnitId.Trim().ToUpperInvariant();
    }
}
