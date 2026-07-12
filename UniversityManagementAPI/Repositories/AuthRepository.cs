using Oracle.ManagedDataAccess.Client;
using System.Data;

public sealed class AuthRepository : IAuthRepository
{
    private readonly IConfiguration _configuration;

    public AuthRepository(IConfiguration configuration)
    {
        _configuration = configuration;
    }

    public async Task<OracleLoginResult?> AuthenticateAsync(
        string username,
        string password,
        CancellationToken cancellationToken)
    {
        var dataSource = _configuration["Oracle:DataSource"];
        if (string.IsNullOrWhiteSpace(dataSource))
        {
            throw new InvalidOperationException("Oracle:DataSource is required.");
        }

        var normalizedUsername = username.Trim().ToUpperInvariant();
        var connectionString = new OracleConnectionStringBuilder
        {
            UserID = normalizedUsername,
            Password = password,
            DataSource = dataSource,
            Pooling = true
        }.ConnectionString;

        try
        {
            await using var connection = new OracleConnection(connectionString);
            await connection.OpenAsync(cancellationToken);

            await using var command = connection.CreateCommand();
            command.CommandText = """
                SELECT
                    SYS_CONTEXT('UNIVERSITY_CTX', 'DB_USERNAME') AS DB_USERNAME,
                    SYS_CONTEXT('UNIVERSITY_CTX', 'IDENTITY_TYPE') AS IDENTITY_TYPE,
                    SYS_CONTEXT('UNIVERSITY_CTX', 'ROLE_CODE') AS ROLE_CODE,
                    SYS_CONTEXT('UNIVERSITY_CTX', 'STAFF_ID') AS STAFF_ID,
                    SYS_CONTEXT('UNIVERSITY_CTX', 'STUDENT_ID') AS STUDENT_ID,
                    SYS_CONTEXT('UNIVERSITY_CTX', 'UNIT_ID') AS UNIT_ID,
                    SYS_CONTEXT('UNIVERSITY_CTX', 'PROGRAM_ID') AS PROGRAM_ID,
                    SYS_CONTEXT('UNIVERSITY_CTX', 'MAJOR_ID') AS MAJOR_ID,
                    SYS_CONTEXT('UNIVERSITY_CTX', 'CAMPUS_ID') AS CAMPUS_ID
                FROM DUAL
                """;
            command.CommandType = CommandType.Text;

            await using var reader = await command.ExecuteReaderAsync(cancellationToken);
            if (!await reader.ReadAsync(cancellationToken))
            {
                return null;
            }

            var contextUsername = ReadNullableString(reader, "DB_USERNAME");
            var identityType = ReadNullableString(reader, "IDENTITY_TYPE");
            var roleCode = ReadNullableString(reader, "ROLE_CODE");

            if (!string.Equals(
                    contextUsername,
                    normalizedUsername,
                    StringComparison.Ordinal) ||
                string.IsNullOrWhiteSpace(identityType) ||
                string.IsNullOrWhiteSpace(roleCode))
            {
                return null;
            }

            var user = new AuthenticatedUser(
                contextUsername!,
                identityType!,
                roleCode!,
                ReadNullableString(reader, "STAFF_ID"),
                ReadNullableString(reader, "STUDENT_ID"),
                ReadNullableString(reader, "UNIT_ID"),
                ReadNullableString(reader, "PROGRAM_ID"),
                ReadNullableString(reader, "MAJOR_ID"),
                ReadNullableString(reader, "CAMPUS_ID"));

            if (!UniversityIdentityValidator.IsTrusted(user))
            {
                return null;
            }

            return new OracleLoginResult(user, connectionString);
        }
        catch (OracleException)
        {
            return null;
        }
    }

    private static string? ReadNullableString(IDataRecord reader, string name)
    {
        var ordinal = reader.GetOrdinal(name);
        return reader.IsDBNull(ordinal) ? null : reader.GetString(ordinal);
    }
}
