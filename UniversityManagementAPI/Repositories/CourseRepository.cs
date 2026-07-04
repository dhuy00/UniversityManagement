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

    private static int ReadInt32(IDataRecord reader, string name)
    {
        return Convert.ToInt32(reader.GetDecimal(reader.GetOrdinal(name)));
    }
}
