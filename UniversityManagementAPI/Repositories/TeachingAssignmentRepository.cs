using System.Data;

public sealed class TeachingAssignmentRepository
    : ITeachingAssignmentRepository
{
    private readonly IDbConnectionFactory _connectionFactory;

    public TeachingAssignmentRepository(IDbConnectionFactory connectionFactory)
    {
        _connectionFactory = connectionFactory;
    }

    public async Task<IReadOnlyList<TeachingAssignmentDto>> GetAllAsync(
        CancellationToken cancellationToken)
    {
        var assignments = new List<TeachingAssignmentDto>();

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
                ta.PROGRAM_ID
            FROM UNIVERSITY_APP.TEACHING_ASSIGNMENTS ta
            JOIN UNIVERSITY_APP.COURSES c
              ON c.COURSE_ID = ta.COURSE_ID
            ORDER BY
                ta.ACADEMIC_YEAR DESC,
                ta.SEMESTER,
                ta.LECTURER_ID,
                ta.COURSE_ID,
                ta.PROGRAM_ID
            """;

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            assignments.Add(new TeachingAssignmentDto
            {
                LecturerId = reader.GetString(reader.GetOrdinal("LECTURER_ID")),
                CourseId = reader.GetString(reader.GetOrdinal("COURSE_ID")),
                CourseName = reader.GetString(reader.GetOrdinal("COURSE_NAME")),
                Semester = ReadInt32(reader, "SEMESTER"),
                AcademicYear = ReadInt32(reader, "ACADEMIC_YEAR"),
                ProgramId = reader.GetString(reader.GetOrdinal("PROGRAM_ID"))
            });
        }

        return assignments;
    }

    private static int ReadInt32(IDataRecord reader, string name)
    {
        return Convert.ToInt32(reader.GetDecimal(reader.GetOrdinal(name)));
    }
}
