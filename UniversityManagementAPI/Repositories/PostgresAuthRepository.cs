using Npgsql;

public sealed class PostgresAuthRepository : IPostgresAuthRepository
{
    private const string FindActiveUserSql = """
        SELECT *
        FROM university.find_active_authentication_candidate($1::varchar)
        """;

    private readonly PostgresAuthenticationDataSource _authenticationDataSource;

    public PostgresAuthRepository(
        PostgresAuthenticationDataSource authenticationDataSource)
    {
        _authenticationDataSource = authenticationDataSource;
    }

    public async Task<PostgresAuthenticationCandidate?> FindActiveByUsernameAsync(
        string username,
        CancellationToken cancellationToken)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(username);

        await using var command = _authenticationDataSource.DataSource.CreateCommand(
            FindActiveUserSql);
        command.Parameters.AddWithValue(username.Trim());

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        if (!await reader.ReadAsync(cancellationToken))
        {
            return null;
        }

        return new PostgresAuthenticationCandidate(
            reader.GetInt64(0),
            reader.GetString(1),
            reader.GetString(2),
            reader.GetFieldValue<string[]>(3),
            ReadNullableString(reader, 4),
            ReadNullableString(reader, 5),
            ReadNullableString(reader, 6),
            ReadNullableString(reader, 7),
            ReadNullableString(reader, 8),
            ReadNullableString(reader, 9),
            ReadNullableString(reader, 10));
    }

    private static string? ReadNullableString(NpgsqlDataReader reader, int ordinal) =>
        reader.IsDBNull(ordinal) ? null : reader.GetString(ordinal);
}
