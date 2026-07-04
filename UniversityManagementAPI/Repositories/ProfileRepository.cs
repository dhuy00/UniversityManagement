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

    public async Task<bool> UpdateContactAsync(
        string identityType,
        string identityId,
        UpdateContactRequest request,
        CancellationToken cancellationToken)
    {
        var isStaff = identityType == "STAFF";
        var isStudent = identityType == "STUDENT";
        if (!isStaff && !isStudent)
        {
            return false;
        }

        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);
        await using var transaction = connection.BeginTransaction();

        await using var command = connection.CreateCommand();
        command.Transaction = transaction;
        command.BindByName = true;
        command.CommandType = CommandType.Text;
        command.CommandText = isStaff
            ? """
              UPDATE UNIVERSITY_APP.STAFF
              SET PHONE = :phone
              WHERE STAFF_ID = :identity_id
              """
            : """
              UPDATE UNIVERSITY_APP.STUDENTS
              SET
                  PHONE = :phone,
                  ADDRESS = :address
              WHERE STUDENT_ID = :identity_id
              """;

        AddNullableVarchar(command, "phone", request.Phone);
        if (isStudent)
        {
            AddNullableVarchar(command, "address", request.Address);
        }
        command.Parameters.Add("identity_id", OracleDbType.Varchar2).Value =
            identityId;

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

    private static string? ReadNullableString(IDataRecord reader, string name)
    {
        var ordinal = reader.GetOrdinal(name);
        return reader.IsDBNull(ordinal) ? null : reader.GetString(ordinal);
    }

    private static void AddNullableVarchar(
        OracleCommand command,
        string name,
        string? value)
    {
        command.Parameters.Add(name, OracleDbType.Varchar2).Value =
            string.IsNullOrWhiteSpace(value) ? DBNull.Value : value.Trim();
    }
}
