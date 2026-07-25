using Npgsql;
using UniversityManagementAPI.Repositories.Interfaces;

namespace UniversityManagementAPI.Repositories;

public sealed class PostgresPermissionRepository : IPostgresPermissionRepository
{
    private readonly IPostgresRequestTransaction _transaction;

    public PostgresPermissionRepository(IPostgresRequestTransaction transaction)
    {
        _transaction = transaction;
    }

    public async Task<List<PermissionDto>> GetAllPermissionsAsync(
        CancellationToken cancellationToken = default)
    {
        const string sql = """
            SELECT
                rp.role_code,
                p.permission_code,
                p.description
            FROM university.permissions p
            LEFT JOIN university.role_permissions rp
                ON p.permission_code = rp.permission_code
            ORDER BY rp.role_code, p.permission_code
            """;

        await using var command = new NpgsqlCommand(
            sql,
            _transaction.Connection,
            _transaction.Transaction);

        var permissions = new List<PermissionDto>();
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            permissions.Add(new PermissionDto
            {
                RoleCode = reader.IsDBNull(0) ? string.Empty : reader.GetString(0),
                PermissionCode = reader.GetString(1),
                PermissionName = reader.GetString(1),
                PermissionDescription = reader.IsDBNull(2) ? string.Empty : reader.GetString(2)
            });
        }

        return permissions;
    }

    public async Task<List<PermissionDto>> GetPermissionsByRoleAsync(
        string roleCode,
        CancellationToken cancellationToken = default)
    {
        const string sql = """
            SELECT
                p.permission_code,
                p.description
            FROM university.permissions p
            JOIN university.role_permissions rp
                ON p.permission_code = rp.permission_code
            WHERE rp.role_code = $1
            ORDER BY p.permission_code
            """;

        await using var command = new NpgsqlCommand(
            sql,
            _transaction.Connection,
            _transaction.Transaction);
        command.Parameters.AddWithValue(roleCode.Trim().ToUpperInvariant());

        var permissions = new List<PermissionDto>();
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            permissions.Add(new PermissionDto
            {
                RoleCode = roleCode.Trim().ToUpperInvariant(),
                PermissionCode = reader.GetString(0),
                PermissionName = reader.GetString(0),
                PermissionDescription = reader.IsDBNull(1) ? string.Empty : reader.GetString(1)
            });
        }

        return permissions;
    }

    public async Task<ApiResponse<object>> AssignPermissionToRoleAsync(
        string roleCode,
        string permissionCode,
        CancellationToken cancellationToken = default)
    {
        try
        {
            const string sql = """
                INSERT INTO university.role_permissions (role_code, permission_code)
                VALUES ($1, $2)
                ON CONFLICT DO NOTHING
                """;

            await using var command = new NpgsqlCommand(
                sql,
                _transaction.Connection,
                _transaction.Transaction);
            command.Parameters.AddWithValue(roleCode.Trim().ToUpperInvariant());
            command.Parameters.AddWithValue(permissionCode.Trim().ToUpperInvariant());

            await command.ExecuteNonQueryAsync(cancellationToken);

            return new ApiResponse<object>
            {
                Success = true,
                Message = "Permission assigned to role successfully.",
                Data = null
            };
        }
        catch (Exception ex)
        {
            return new ApiResponse<object>
            {
                Success = false,
                Message = ex.Message,
                Data = null
            };
        }
    }

    public async Task<ApiResponse<object>> RevokePermissionFromRoleAsync(
        string roleCode,
        string permissionCode,
        CancellationToken cancellationToken = default)
    {
        try
        {
            const string sql = """
                DELETE FROM university.role_permissions
                WHERE role_code = $1 AND permission_code = $2
                """;

            await using var command = new NpgsqlCommand(
                sql,
                _transaction.Connection,
                _transaction.Transaction);
            command.Parameters.AddWithValue(roleCode.Trim().ToUpperInvariant());
            command.Parameters.AddWithValue(permissionCode.Trim().ToUpperInvariant());

            await command.ExecuteNonQueryAsync(cancellationToken);

            return new ApiResponse<object>
            {
                Success = true,
                Message = "Permission revoked from role successfully.",
                Data = null
            };
        }
        catch (Exception ex)
        {
            return new ApiResponse<object>
            {
                Success = false,
                Message = ex.Message,
                Data = null
            };
        }
    }
}
