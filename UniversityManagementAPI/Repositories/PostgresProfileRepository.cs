using Npgsql;
using UniversityManagementAPI.Repositories.Interfaces;

namespace UniversityManagementAPI.Repositories;

public sealed class PostgresProfileRepository : IPostgresProfileRepository
{
    private readonly IPostgresRequestTransaction _transaction;

    public PostgresProfileRepository(IPostgresRequestTransaction transaction)
    {
        _transaction = transaction;
    }

    public async Task<ProfileDto?> GetStaffProfileAsync(
        string staffId,
        CancellationToken cancellationToken = default)
    {
        const string sql = """
            SELECT
                s.staff_id,
                s.full_name,
                s.gender,
                s.date_of_birth,
                s.allowance,
                s.phone,
                s.unit_id,
                u.unit_name,
                s.campus_id,
                r.role_code
            FROM university.staff s
            JOIN university.units u ON u.unit_id = s.unit_id
            JOIN university.app_user_roles aur ON aur.user_id = s.user_id
            JOIN university.roles r ON r.role_code = aur.role_code
            WHERE s.staff_id = $1
            ORDER BY
                CASE r.role_code
                    WHEN 'DEAN' THEN 1
                    WHEN 'UNIT_HEAD' THEN 2
                    WHEN 'ACADEMIC_AFFAIRS' THEN 3
                    WHEN 'LECTURER' THEN 4
                    WHEN 'BASIC_STAFF' THEN 5
                    ELSE 6
                END
            LIMIT 1
            """;

        await using var command = new NpgsqlCommand(sql, _transaction.Connection, _transaction.Transaction);
        command.Parameters.AddWithValue(staffId);

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        if (!await reader.ReadAsync(cancellationToken))
        {
            return null;
        }

        return new ProfileDto
        {
            Id = reader.GetString(reader.GetOrdinal("staff_id")),
            FullName = reader.GetString(reader.GetOrdinal("full_name")),
            Gender = reader.GetString(reader.GetOrdinal("gender")),
            DateOfBirth = reader.GetDateTime(reader.GetOrdinal("date_of_birth")),
            Allowance = reader.GetDecimal(reader.GetOrdinal("allowance")),
            Phone = reader.IsDBNull(reader.GetOrdinal("phone")) ? null : reader.GetString(reader.GetOrdinal("phone")),
            IdentityType = "STAFF",
            RoleCode = reader.GetString(reader.GetOrdinal("role_code")),
            UnitId = reader.GetString(reader.GetOrdinal("unit_id")),
            UnitName = reader.GetString(reader.GetOrdinal("unit_name")),
            CampusId = reader.GetString(reader.GetOrdinal("campus_id"))
        };
    }

    public async Task<ProfileDto?> GetStudentProfileAsync(
        string studentId,
        CancellationToken cancellationToken = default)
    {
        const string sql = """
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
            WHERE student_id = $1
            """;

        await using var command = new NpgsqlCommand(sql, _transaction.Connection, _transaction.Transaction);
        command.Parameters.AddWithValue(studentId);

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        if (!await reader.ReadAsync(cancellationToken))
        {
            return null;
        }

        return new ProfileDto
        {
            Id = reader.GetString(reader.GetOrdinal("student_id")),
            FullName = reader.GetString(reader.GetOrdinal("full_name")),
            Gender = reader.GetString(reader.GetOrdinal("gender")),
            DateOfBirth = reader.GetDateTime(reader.GetOrdinal("date_of_birth")),
            Address = reader.IsDBNull(reader.GetOrdinal("address")) ? null : reader.GetString(reader.GetOrdinal("address")),
            Phone = reader.IsDBNull(reader.GetOrdinal("phone")) ? null : reader.GetString(reader.GetOrdinal("phone")),
            IdentityType = "STUDENT",
            ProgramId = reader.GetString(reader.GetOrdinal("program_id")),
            MajorId = reader.GetString(reader.GetOrdinal("major_id")),
            AccumulatedCredits = reader.GetInt16(reader.GetOrdinal("accumulated_credits")),
            CumulativeGpa = reader.GetDecimal(reader.GetOrdinal("cumulative_gpa")),
            CampusId = reader.GetString(reader.GetOrdinal("campus_id"))
        };
    }

    public async Task<bool> UpdateContactAsync(
        string identityType,
        string identityId,
        UpdateContactRequest request,
        CancellationToken cancellationToken = default)
    {
        if (identityType == "STAFF")
        {
            return await UpdateStaffPhoneAsync(identityId, request.Phone, cancellationToken);
        }

        if (identityType == "STUDENT")
        {
            return await UpdateStudentContactAsync(identityId, request.Phone, request.Address, cancellationToken);
        }

        return false;
    }

    private async Task<bool> UpdateStaffPhoneAsync(
        string staffId,
        string? phone,
        CancellationToken cancellationToken)
    {
        const string sql = """
            UPDATE university.staff
            SET phone = $2
            WHERE staff_id = $1
            """;

        await using var command = new NpgsqlCommand(sql, _transaction.Connection, _transaction.Transaction);
        command.Parameters.AddWithValue(staffId);
        command.Parameters.AddWithValue(phone ?? (object)DBNull.Value);

        var updated = await command.ExecuteNonQueryAsync(cancellationToken);
        return updated == 1;
    }

    private async Task<bool> UpdateStudentContactAsync(
        string studentId,
        string? phone,
        string? address,
        CancellationToken cancellationToken)
    {
        const string sql = """
            UPDATE university.students
            SET
                phone = $2,
                address = $3
            WHERE student_id = $1
            """;

        await using var command = new NpgsqlCommand(sql, _transaction.Connection, _transaction.Transaction);
        command.Parameters.AddWithValue(studentId);
        command.Parameters.AddWithValue(phone ?? (object)DBNull.Value);
        command.Parameters.AddWithValue(address ?? (object)DBNull.Value);

        var updated = await command.ExecuteNonQueryAsync(cancellationToken);
        return updated == 1;
    }
}
