using Oracle.ManagedDataAccess.Client;
using System.Data;

public sealed class StudentRepository : IStudentRepository
{
    private readonly IDbConnectionFactory _connectionFactory;

    public StudentRepository(IDbConnectionFactory connectionFactory)
    {
        _connectionFactory = connectionFactory;
    }

    public async Task<PagedResult<StudentDto>> GetPageAsync(
        int page,
        int pageSize,
        string? search,
        CancellationToken cancellationToken)
    {
        var students = new List<StudentDto>();
        var normalizedSearch = string.IsNullOrWhiteSpace(search)
            ? null
            : search.Trim();
        var searchSql = normalizedSearch is null
            ? string.Empty
            : """
              WHERE UPPER(STUDENT_ID) LIKE '%' || UPPER(:search) || '%'
                 OR UPPER(FULL_NAME) LIKE '%' || UPPER(:search) || '%'
              """;

        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);

        await using var countCommand = connection.CreateCommand();
        countCommand.BindByName = true;
        countCommand.CommandType = CommandType.Text;
        countCommand.CommandText = $"""
            SELECT COUNT(*)
            FROM UNIVERSITY_APP.STUDENTS
            {searchSql}
            """;
        AddSearchParameter(countCommand, normalizedSearch);

        var totalItems = Convert.ToInt32(
            await countCommand.ExecuteScalarAsync(cancellationToken));
        var offset = (page - 1) * pageSize;

        await using var command = connection.CreateCommand();
        command.BindByName = true;
        command.CommandType = CommandType.Text;
        command.CommandText = $"""
            SELECT
                STUDENT_ID,
                FULL_NAME,
                GENDER,
                DATE_OF_BIRTH,
                ADDRESS,
                PHONE,
                PROGRAM_ID,
                MAJOR_ID,
                ACCUMULATED_CREDITS,
                CUMULATIVE_GPA,
                CAMPUS_ID
            FROM UNIVERSITY_APP.STUDENTS
            {searchSql}
            ORDER BY STUDENT_ID
            OFFSET :offset ROWS FETCH NEXT :page_size ROWS ONLY
            """;
        AddSearchParameter(command, normalizedSearch);
        command.Parameters.Add("offset", OracleDbType.Int32).Value = offset;
        command.Parameters.Add("page_size", OracleDbType.Int32).Value = pageSize;

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            students.Add(new StudentDto
            {
                StudentId = reader.GetString(reader.GetOrdinal("STUDENT_ID")),
                FullName = reader.GetString(reader.GetOrdinal("FULL_NAME")),
                Gender = reader.GetString(reader.GetOrdinal("GENDER")),
                DateOfBirth = reader.GetDateTime(reader.GetOrdinal("DATE_OF_BIRTH")),
                Address = ReadNullableString(reader, "ADDRESS"),
                Phone = ReadNullableString(reader, "PHONE"),
                ProgramId = reader.GetString(reader.GetOrdinal("PROGRAM_ID")),
                MajorId = reader.GetString(reader.GetOrdinal("MAJOR_ID")),
                AccumulatedCredits = ReadInt32(reader, "ACCUMULATED_CREDITS"),
                CumulativeGpa = reader.GetDecimal(
                    reader.GetOrdinal("CUMULATIVE_GPA")),
                CampusId = reader.GetString(reader.GetOrdinal("CAMPUS_ID"))
            });
        }

        return new PagedResult<StudentDto>(
            students,
            page,
            pageSize,
            totalItems);
    }

    private static void AddSearchParameter(
        OracleCommand command,
        string? search)
    {
        if (search is not null)
        {
            command.Parameters.Add("search", OracleDbType.Varchar2).Value = search;
        }
    }

    private static int ReadInt32(IDataRecord reader, string name)
    {
        return Convert.ToInt32(reader.GetDecimal(reader.GetOrdinal(name)));
    }

    private static string? ReadNullableString(IDataRecord reader, string name)
    {
        var ordinal = reader.GetOrdinal(name);
        return reader.IsDBNull(ordinal) ? null : reader.GetString(ordinal);
    }
}
