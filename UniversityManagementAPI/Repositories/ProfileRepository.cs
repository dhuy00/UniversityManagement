using Oracle.ManagedDataAccess.Client;
using System.Data;

public sealed class ProfileRepository : IProfileRepository
{
    private readonly IDbConnectionFactory _connectionFactory;

    public ProfileRepository(IDbConnectionFactory connectionFactory)
    {
        _connectionFactory = connectionFactory;
    }

    public async Task<ProfileDto?> GetStaffProfileAsync(
        string staffId,
        CancellationToken cancellationToken)
    {
        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);

        await using var command = connection.CreateCommand();
        command.BindByName = true;
        command.CommandType = CommandType.Text;
        command.CommandText = """
            SELECT
                s.STAFF_ID,
                s.FULL_NAME,
                s.GENDER,
                s.DATE_OF_BIRTH,
                s.ALLOWANCE,
                s.PHONE,
                s.ROLE_CODE,
                s.UNIT_ID,
                u.UNIT_NAME,
                s.CAMPUS_ID
            FROM UNIVERSITY_APP.STAFF s
            JOIN UNIVERSITY_APP.UNITS u
              ON u.UNIT_ID = s.UNIT_ID
            WHERE s.STAFF_ID = :staff_id
            """;
        command.Parameters.Add("staff_id", OracleDbType.Varchar2).Value = staffId;

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        if (!await reader.ReadAsync(cancellationToken))
        {
            return null;
        }

        return new ProfileDto
        {
            Id = reader.GetString(reader.GetOrdinal("STAFF_ID")),
            FullName = reader.GetString(reader.GetOrdinal("FULL_NAME")),
            Gender = reader.GetString(reader.GetOrdinal("GENDER")),
            DateOfBirth = reader.GetDateTime(reader.GetOrdinal("DATE_OF_BIRTH")),
            Allowance = reader.GetDecimal(reader.GetOrdinal("ALLOWANCE")),
            Phone = ReadNullableString(reader, "PHONE"),
            IdentityType = "STAFF",
            RoleCode = reader.GetString(reader.GetOrdinal("ROLE_CODE")),
            UnitId = reader.GetString(reader.GetOrdinal("UNIT_ID")),
            UnitName = reader.GetString(reader.GetOrdinal("UNIT_NAME")),
            CampusId = reader.GetString(reader.GetOrdinal("CAMPUS_ID"))
        };
    }

    public async Task<ProfileDto?> GetStudentProfileAsync(
        string studentId,
        CancellationToken cancellationToken)
    {
        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);

        await using var command = connection.CreateCommand();
        command.BindByName = true;
        command.CommandType = CommandType.Text;
        command.CommandText = """
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
            WHERE STUDENT_ID = :student_id
            """;
        command.Parameters.Add("student_id", OracleDbType.Varchar2).Value = studentId;

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        if (!await reader.ReadAsync(cancellationToken))
        {
            return null;
        }

        return new ProfileDto
        {
            Id = reader.GetString(reader.GetOrdinal("STUDENT_ID")),
            FullName = reader.GetString(reader.GetOrdinal("FULL_NAME")),
            Gender = reader.GetString(reader.GetOrdinal("GENDER")),
            DateOfBirth = reader.GetDateTime(reader.GetOrdinal("DATE_OF_BIRTH")),
            Address = ReadNullableString(reader, "ADDRESS"),
            Phone = ReadNullableString(reader, "PHONE"),
            IdentityType = "STUDENT",
            ProgramId = reader.GetString(reader.GetOrdinal("PROGRAM_ID")),
            MajorId = reader.GetString(reader.GetOrdinal("MAJOR_ID")),
            AccumulatedCredits = Convert.ToInt32(
                reader.GetDecimal(reader.GetOrdinal("ACCUMULATED_CREDITS"))),
            CumulativeGpa = reader.GetDecimal(reader.GetOrdinal("CUMULATIVE_GPA")),
            CampusId = reader.GetString(reader.GetOrdinal("CAMPUS_ID"))
        };
    }

    private static string? ReadNullableString(IDataRecord reader, string name)
    {
        var ordinal = reader.GetOrdinal(name);
        return reader.IsDBNull(ordinal) ? null : reader.GetString(ordinal);
    }
}
