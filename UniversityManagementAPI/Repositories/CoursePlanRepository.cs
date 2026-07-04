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
                cp.SEMESTER,
                cp.ACADEMIC_YEAR,
                cp.PROGRAM_ID,
                cp.START_DATE
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
                Semester = ReadInt32(reader, "SEMESTER"),
                AcademicYear = ReadInt32(reader, "ACADEMIC_YEAR"),
                ProgramId = reader.GetString(reader.GetOrdinal("PROGRAM_ID")),
                StartDate = reader.GetDateTime(reader.GetOrdinal("START_DATE"))
            });
        }

        return plans;
    }

    private static int ReadInt32(IDataRecord reader, string name)
    {
        return Convert.ToInt32(reader.GetDecimal(reader.GetOrdinal(name)));
    }
}
