using Npgsql;
using UniversityManagementAPI.Repositories.Interfaces;

namespace UniversityManagementAPI.Repositories;

public sealed class PostgresStudentRepository : IPostgresStudentRepository
{
    private readonly IPostgresRequestTransaction _transaction;

    public PostgresStudentRepository(IPostgresRequestTransaction transaction)
    {
        _transaction = transaction;
    }

    public async Task<PagedResult<StudentDto>> GetPageAsync(
        int page,
        int pageSize,
        string? search,
        CancellationToken cancellationToken = default)
    {
        var normalizedSearch = string.IsNullOrWhiteSpace(search)
            ? null
            : search.Trim();
        var offset = (page - 1) * pageSize;
        var searchParamIndex = normalizedSearch is not null ? 1 : 0;
        var searchSql = normalizedSearch is null
            ? string.Empty
            : $"""
              WHERE student_id ILIKE '%' || ${searchParamIndex} || '%'
                 OR full_name ILIKE '%' || ${searchParamIndex} || '%'
              """;

        await using var connection = _transaction.Connection;
        await using var transaction = _transaction.Transaction;

        await using var countCommand = new NpgsqlCommand(
            $"""
             SELECT COUNT(*)
             FROM university.students
             {searchSql}
             """,
            connection,
            transaction);
        if (normalizedSearch is not null)
        {
            countCommand.Parameters.AddWithValue(normalizedSearch);
        }

        var totalItems = Convert.ToInt32(
            await countCommand.ExecuteScalarAsync(cancellationToken));

        await using var command = new NpgsqlCommand(
            $"""
             SELECT
                 student_id,
                 full_name,
                 gender,
                 date_of_birth,
                 address,
                 phone,
                 program_id,
                 major_id,
                 accumulated_credits,
                 cumulative_gpa,
                 campus_id
             FROM university.students
             {searchSql}
             ORDER BY student_id
             LIMIT ${searchParamIndex + 1} OFFSET ${searchParamIndex + 2}
             """,
            connection,
            transaction);
        if (normalizedSearch is not null)
        {
            command.Parameters.AddWithValue(normalizedSearch);
        }
        command.Parameters.AddWithValue(pageSize);
        command.Parameters.AddWithValue(offset);

        var students = new List<StudentDto>();
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            students.Add(new StudentDto
            {
                StudentId = reader.GetString(reader.GetOrdinal("student_id")),
                FullName = reader.GetString(reader.GetOrdinal("full_name")),
                Gender = reader.GetString(reader.GetOrdinal("gender")),
                DateOfBirth = reader.GetDateTime(reader.GetOrdinal("date_of_birth")),
                Address = ReadNullableString(reader, "address"),
                Phone = ReadNullableString(reader, "phone"),
                ProgramId = reader.GetString(reader.GetOrdinal("program_id")),
                MajorId = reader.GetString(reader.GetOrdinal("major_id")),
                AccumulatedCredits = reader.GetInt16(reader.GetOrdinal("accumulated_credits")),
                CumulativeGpa = reader.GetDecimal(reader.GetOrdinal("cumulative_gpa")),
                CampusId = reader.GetString(reader.GetOrdinal("campus_id"))
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
        CancellationToken cancellationToken = default)
    {
        var userId = await ResolveUserIdAsync(
            request.OracleUsername,
            cancellationToken);

        const string sql = """
            INSERT INTO university.students (
                student_id,
                user_id,
                full_name,
                gender,
                date_of_birth,
                address,
                phone,
                program_id,
                major_id,
                accumulated_credits,
                cumulative_gpa,
                campus_id
            ) VALUES (
                $1,
                $2,
                $3,
                $4,
                $5,
                $6,
                $7,
                $8,
                $9,
                $10,
                $11,
                $12
            )
            """;

        await using var command = new NpgsqlCommand(
            sql,
            _transaction.Connection,
            _transaction.Transaction);
        command.Parameters.AddWithValue(request.StudentId.Trim().ToUpperInvariant());
        command.Parameters.AddWithValue(userId);
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

        await command.ExecuteNonQueryAsync(cancellationToken);
    }

    public async Task<bool> UpdateAsync(
        string studentId,
        UpdateStudentRequest request,
        CancellationToken cancellationToken = default)
    {
        const string sql = """
            UPDATE university.students
            SET
                full_name = $1,
                gender = $2,
                date_of_birth = $3,
                address = $4,
                phone = $5,
                program_id = $6,
                major_id = $7,
                accumulated_credits = $8,
                cumulative_gpa = $9,
                campus_id = $10
            WHERE student_id = $11
            """;

        await using var command = new NpgsqlCommand(
            sql,
            _transaction.Connection,
            _transaction.Transaction);
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
        command.Parameters.AddWithValue(studentId.Trim().ToUpperInvariant());

        var updated = await command.ExecuteNonQueryAsync(cancellationToken);
        return updated == 1;
    }

    private async Task<long> ResolveUserIdAsync(
        string username,
        CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT user_id
            FROM university.app_users
            WHERE lower(username) = lower($1)
            """;

        await using var command = new NpgsqlCommand(
            sql,
            _transaction.Connection,
            _transaction.Transaction);
        command.Parameters.AddWithValue(username.Trim());

        var result = await command.ExecuteScalarAsync(cancellationToken);
        if (result is null || result is DBNull)
        {
            throw new InvalidOperationException(
                $"No active app_users row found for username '{username}'.");
        }

        return Convert.ToInt64(result);
    }

    private static string? ReadNullableString(NpgsqlDataReader reader, string name)
    {
        var ordinal = reader.GetOrdinal(name);
        return reader.IsDBNull(ordinal) ? null : reader.GetString(ordinal);
    }

    private static void AddCommonParameters(
        NpgsqlCommand command,
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
        command.Parameters.AddWithValue(fullName.Trim());
        command.Parameters.AddWithValue(gender.Trim().ToUpperInvariant());
        command.Parameters.AddWithValue(dateOfBirth);
        command.Parameters.AddWithValue(DbValue(address));
        command.Parameters.AddWithValue(DbValue(phone));
        command.Parameters.AddWithValue(programId.Trim().ToUpperInvariant());
        command.Parameters.AddWithValue(majorId.Trim().ToUpperInvariant());
        command.Parameters.AddWithValue(accumulatedCredits);
        command.Parameters.AddWithValue(cumulativeGpa);
        command.Parameters.AddWithValue(campusId.Trim().ToUpperInvariant());
    }

    private static object DbValue(string? value)
    {
        return string.IsNullOrWhiteSpace(value)
            ? DBNull.Value
            : value.Trim();
    }
}