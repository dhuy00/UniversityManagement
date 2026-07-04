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

    public async Task CreateAsync(
        CreateStudentRequest request,
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
            INSERT INTO UNIVERSITY_APP.STUDENTS (
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
                ORACLE_USERNAME,
                CAMPUS_ID
            ) VALUES (
                :student_id,
                :full_name,
                :gender,
                :date_of_birth,
                :address,
                :phone,
                :program_id,
                :major_id,
                :accumulated_credits,
                :cumulative_gpa,
                :oracle_username,
                :campus_id
            )
            """;
        AddCommonParameters(
            command,
            request.FullName,
            request.Gender,
            request.DateOfBirth,
            request.Address,
            request.Phone,
            request.ProgramId,
            request.MajorId,
            request.AccumulatedCredits,
            request.CumulativeGpa,
            request.CampusId);
        command.Parameters.Add("student_id", OracleDbType.Varchar2).Value =
            request.StudentId.Trim().ToUpperInvariant();
        command.Parameters.Add("oracle_username", OracleDbType.Varchar2).Value =
            request.OracleUsername.Trim().ToUpperInvariant();

        await command.ExecuteNonQueryAsync(cancellationToken);
        await transaction.CommitAsync(cancellationToken);
    }

    public async Task<bool> UpdateAsync(
        string studentId,
        UpdateStudentRequest request,
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
            UPDATE UNIVERSITY_APP.STUDENTS
            SET
                FULL_NAME = :full_name,
                GENDER = :gender,
                DATE_OF_BIRTH = :date_of_birth,
                ADDRESS = :address,
                PHONE = :phone,
                PROGRAM_ID = :program_id,
                MAJOR_ID = :major_id,
                ACCUMULATED_CREDITS = :accumulated_credits,
                CUMULATIVE_GPA = :cumulative_gpa,
                CAMPUS_ID = :campus_id
            WHERE STUDENT_ID = :student_id
            """;
        AddCommonParameters(
            command,
            request.FullName,
            request.Gender,
            request.DateOfBirth,
            request.Address,
            request.Phone,
            request.ProgramId,
            request.MajorId,
            request.AccumulatedCredits,
            request.CumulativeGpa,
            request.CampusId);
        command.Parameters.Add("student_id", OracleDbType.Varchar2).Value =
            studentId.Trim().ToUpperInvariant();

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

    private static void AddCommonParameters(
        OracleCommand command,
        string fullName,
        string gender,
        DateTime dateOfBirth,
        string? address,
        string? phone,
        string programId,
        string majorId,
        int accumulatedCredits,
        decimal cumulativeGpa,
        string campusId)
    {
        command.Parameters.Add("full_name", OracleDbType.Varchar2).Value =
            fullName.Trim();
        command.Parameters.Add("gender", OracleDbType.Varchar2).Value =
            gender.Trim().ToUpperInvariant();
        command.Parameters.Add("date_of_birth", OracleDbType.Date).Value =
            dateOfBirth;
        command.Parameters.Add("address", OracleDbType.Varchar2).Value =
            DbValue(address);
        command.Parameters.Add("phone", OracleDbType.Varchar2).Value =
            DbValue(phone);
        command.Parameters.Add("program_id", OracleDbType.Varchar2).Value =
            programId.Trim().ToUpperInvariant();
        command.Parameters.Add("major_id", OracleDbType.Varchar2).Value =
            majorId.Trim().ToUpperInvariant();
        command.Parameters.Add("accumulated_credits", OracleDbType.Int32).Value =
            accumulatedCredits;
        command.Parameters.Add("cumulative_gpa", OracleDbType.Decimal).Value =
            cumulativeGpa;
        command.Parameters.Add("campus_id", OracleDbType.Varchar2).Value =
            campusId.Trim().ToUpperInvariant();
    }

    private static object DbValue(string? value)
    {
        return string.IsNullOrWhiteSpace(value)
            ? DBNull.Value
            : value.Trim();
    }
}
