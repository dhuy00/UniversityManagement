using Npgsql;
using UniversityManagementAPI.Repositories.Interfaces;

namespace UniversityManagementAPI.Repositories;

public sealed class PostgresStaffRepository : IPostgresStaffRepository
{
    private readonly IPostgresRequestTransaction _transaction;

    public PostgresStaffRepository(IPostgresRequestTransaction transaction)
    {
        _transaction = transaction;
    }

    public async Task<IReadOnlyList<StaffDto>> GetAllAsync(
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
                au.username AS oracle_username,
                s.campus_id,
                r.role_code
            FROM university.staff s
            JOIN university.app_users au
              ON au.user_id = s.user_id
            LEFT JOIN LATERAL (
                SELECT aur.role_code
                FROM university.app_user_roles aur
                WHERE aur.user_id = s.user_id
                ORDER BY
                    CASE aur.role_code
                        WHEN 'DEAN' THEN 1
                        WHEN 'UNIT_HEAD' THEN 2
                        WHEN 'ACADEMIC_AFFAIRS' THEN 3
                        WHEN 'LECTURER' THEN 4
                        WHEN 'BASIC_STAFF' THEN 5
                        ELSE 6
                    END
                LIMIT 1
            ) r ON TRUE
            ORDER BY s.staff_id
            """;

        await using var command = new NpgsqlCommand(
            sql,
            _transaction.Connection,
            _transaction.Transaction);

        var staff = new List<StaffDto>();
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            var phoneOrdinal = reader.GetOrdinal("phone");
            staff.Add(new StaffDto
            {
                StaffId = reader.GetString(reader.GetOrdinal("staff_id")),
                FullName = reader.GetString(reader.GetOrdinal("full_name")),
                Gender = reader.GetString(reader.GetOrdinal("gender")),
                DateOfBirth = reader.GetDateTime(reader.GetOrdinal("date_of_birth")),
                Allowance = reader.GetDecimal(reader.GetOrdinal("allowance")),
                Phone = reader.IsDBNull(phoneOrdinal)
                    ? null
                    : reader.GetString(phoneOrdinal),
                RoleCode = reader.IsDBNull(reader.GetOrdinal("role_code"))
                    ? string.Empty
                    : reader.GetString(reader.GetOrdinal("role_code")),
                UnitId = reader.GetString(reader.GetOrdinal("unit_id")),
                OracleUsername = reader.GetString(reader.GetOrdinal("oracle_username")),
                CampusId = reader.GetString(reader.GetOrdinal("campus_id"))
            });
        }

        return staff;
    }

    public async Task CreateAsync(
        CreateStaffRequest request,
        CancellationToken cancellationToken = default)
    {
        var userId = await ResolveUserIdAsync(
            request.OracleUsername,
            cancellationToken);

        const string insertStaff = """
            INSERT INTO university.staff (
                staff_id,
                user_id,
                full_name,
                gender,
                date_of_birth,
                allowance,
                phone,
                unit_id,
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
                $9
            )
            """;

        await using (var command = new NpgsqlCommand(
            insertStaff,
            _transaction.Connection,
            _transaction.Transaction))
        {
            command.Parameters.AddWithValue(request.StaffId.Trim().ToUpperInvariant());
            command.Parameters.AddWithValue(userId);
            command.Parameters.AddWithValue(request.FullName.Trim());
            command.Parameters.AddWithValue(request.Gender.Trim().ToUpperInvariant());
            command.Parameters.AddWithValue(request.DateOfBirth);
            command.Parameters.AddWithValue(request.Allowance);
            command.Parameters.AddWithValue(
                string.IsNullOrWhiteSpace(request.Phone)
                    ? (object)DBNull.Value
                    : request.Phone.Trim());
            command.Parameters.AddWithValue(request.UnitId.Trim().ToUpperInvariant());
            command.Parameters.AddWithValue(request.CampusId.Trim().ToUpperInvariant());

            await command.ExecuteNonQueryAsync(cancellationToken);
        }

        const string upsertRole = """
            INSERT INTO university.app_user_roles (
                user_id,
                role_code
            ) VALUES ($1, $2)
            ON CONFLICT (user_id, role_code) DO NOTHING
            """;

        await using (var command = new NpgsqlCommand(
            upsertRole,
            _transaction.Connection,
            _transaction.Transaction))
        {
            command.Parameters.AddWithValue(userId);
            command.Parameters.AddWithValue(request.RoleCode.Trim().ToUpperInvariant());
            await command.ExecuteNonQueryAsync(cancellationToken);
        }
    }

    public async Task<bool> UpdateAsync(
        string staffId,
        UpdateStaffRequest request,
        CancellationToken cancellationToken = default)
    {
        var userId = await ResolveStaffUserIdAsync(staffId, cancellationToken);
        if (userId is null)
        {
            return false;
        }

        const string updateStaff = """
            UPDATE university.staff
            SET
                full_name = $1,
                gender = $2,
                date_of_birth = $3,
                allowance = $4,
                phone = $5,
                unit_id = $6,
                campus_id = $7
            WHERE staff_id = $8
            """;

        var updated = 0;
        await using (var command = new NpgsqlCommand(
            updateStaff,
            _transaction.Connection,
            _transaction.Transaction))
        {
            command.Parameters.AddWithValue(request.FullName.Trim());
            command.Parameters.AddWithValue(request.Gender.Trim().ToUpperInvariant());
            command.Parameters.AddWithValue(request.DateOfBirth);
            command.Parameters.AddWithValue(request.Allowance);
            command.Parameters.AddWithValue(
                string.IsNullOrWhiteSpace(request.Phone)
                    ? (object)DBNull.Value
                    : request.Phone.Trim());
            command.Parameters.AddWithValue(request.UnitId.Trim().ToUpperInvariant());
            command.Parameters.AddWithValue(request.CampusId.Trim().ToUpperInvariant());
            command.Parameters.AddWithValue(staffId.Trim().ToUpperInvariant());

            updated = await command.ExecuteNonQueryAsync(cancellationToken);
        }

        if (updated != 1)
        {
            return false;
        }

        const string upsertRole = """
            INSERT INTO university.app_user_roles (
                user_id,
                role_code
            ) VALUES ($1, $2)
            ON CONFLICT (user_id, role_code) DO NOTHING
            """;

        await using var roleCommand = new NpgsqlCommand(
            upsertRole,
            _transaction.Connection,
            _transaction.Transaction);
        roleCommand.Parameters.AddWithValue(userId.Value);
        roleCommand.Parameters.AddWithValue(request.RoleCode.Trim().ToUpperInvariant());
        await roleCommand.ExecuteNonQueryAsync(cancellationToken);

        return true;
    }

    public async Task<bool> DeleteAsync(
        string staffId,
        CancellationToken cancellationToken = default)
    {
        var userId = await ResolveStaffUserIdAsync(staffId, cancellationToken);
        if (userId is null)
        {
            return false;
        }

        const string deleteRoles = """
            DELETE FROM university.app_user_roles
            WHERE user_id = $1
            """;

        await using (var roleCommand = new NpgsqlCommand(
            deleteRoles,
            _transaction.Connection,
            _transaction.Transaction))
        {
            roleCommand.Parameters.AddWithValue(userId.Value);
            await roleCommand.ExecuteNonQueryAsync(cancellationToken);
        }

        const string deleteStaff = """
            DELETE FROM university.staff
            WHERE staff_id = $1
            """;

        await using var command = new NpgsqlCommand(
            deleteStaff,
            _transaction.Connection,
            _transaction.Transaction);
        command.Parameters.AddWithValue(staffId.Trim().ToUpperInvariant());

        var deleted = await command.ExecuteNonQueryAsync(cancellationToken);
        return deleted == 1;
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

    private async Task<long?> ResolveStaffUserIdAsync(
        string staffId,
        CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT user_id
            FROM university.staff
            WHERE staff_id = $1
            """;

        await using var command = new NpgsqlCommand(
            sql,
            _transaction.Connection,
            _transaction.Transaction);
        command.Parameters.AddWithValue(staffId.Trim().ToUpperInvariant());

        var result = await command.ExecuteScalarAsync(cancellationToken);
        return result is null || result is DBNull
            ? null
            : Convert.ToInt64(result);
    }
}