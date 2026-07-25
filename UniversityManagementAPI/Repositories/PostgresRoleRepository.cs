using Npgsql;
using UniversityManagementAPI.Repositories.Interfaces;

namespace UniversityManagementAPI.Repositories;

public sealed class PostgresRoleRepository : IPostgresRoleRepository
{
    private readonly IPostgresRequestTransaction _transaction;

    public PostgresRoleRepository(IPostgresRequestTransaction transaction)
    {
        _transaction = transaction;
    }

    public async Task<List<RoleDto>> GetAllRolesAsync(
        CancellationToken cancellationToken = default)
    {
        const string sql = """
            SELECT
                r.role_code,
                COALESCE(r.description, '')
            FROM university.roles r
            ORDER BY r.role_code
            """;

        await using var command = new NpgsqlCommand(
            sql,
            _transaction.Connection,
            _transaction.Transaction);

        var roles = new List<RoleDto>();
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            roles.Add(new RoleDto
            {
                Role = reader.GetString(0),
                AuthenticationType = "DATABASE",
                Common = "NO",
                OracleMaintained = "N"
            });
        }

        return roles;
    }

    public async Task<ApiResponse<object>> CreateRoleAsync(
        string roleCode,
        string description,
        CancellationToken cancellationToken = default)
    {
        try
        {
            const string sql = """
                INSERT INTO university.roles (role_code, description, is_active)
                VALUES ($1, $2, true)
                ON CONFLICT (role_code) DO NOTHING
                """;

            await using var command = new NpgsqlCommand(
                sql,
                _transaction.Connection,
                _transaction.Transaction);
            command.Parameters.AddWithValue(roleCode.Trim().ToUpperInvariant());
            command.Parameters.AddWithValue(description.Trim());

            var inserted = await command.ExecuteNonQueryAsync(cancellationToken);
            if (inserted == 0)
            {
                return new ApiResponse<object>
                {
                    Success = false,
                    Message = $"Role '{roleCode}' already exists.",
                    Data = null
                };
            }

            return new ApiResponse<object>
            {
                Success = true,
                Message = "Role created successfully.",
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

    public async Task<ApiResponse<object>> GrantRoleToUserAsync(
        string username,
        string roleCode,
        CancellationToken cancellationToken = default)
    {
        try
        {
            await using var userIdCommand = new NpgsqlCommand(
                """
                SELECT user_id FROM university.app_users WHERE lower(username) = lower($1)
                """,
                _transaction.Connection,
                _transaction.Transaction);
            userIdCommand.Parameters.AddWithValue(username.Trim());
            var userId = await userIdCommand.ExecuteScalarAsync(cancellationToken);
            if (userId is null or DBNull)
            {
                return new ApiResponse<object>
                {
                    Success = false,
                    Message = $"User '{username}' not found.",
                    Data = null
                };
            }

            await using var roleIdCommand = new NpgsqlCommand(
                """
                SELECT role_id FROM university.roles WHERE role_code = $1
                """,
                _transaction.Connection,
                _transaction.Transaction);
            roleIdCommand.Parameters.AddWithValue(roleCode.Trim().ToUpperInvariant());
            var roleId = await roleIdCommand.ExecuteScalarAsync(cancellationToken);
            if (roleId is null or DBNull)
            {
                return new ApiResponse<object>
                {
                    Success = false,
                    Message = $"Role '{roleCode}' not found.",
                    Data = null
                };
            }

            const string sql = """
                INSERT INTO university.app_user_roles (user_id, role_id)
                VALUES ($1, $2)
                ON CONFLICT DO NOTHING
                """;

            await using var command = new NpgsqlCommand(
                sql,
                _transaction.Connection,
                _transaction.Transaction);
            command.Parameters.AddWithValue(userId);
            command.Parameters.AddWithValue(roleId);

            await command.ExecuteNonQueryAsync(cancellationToken);

            return new ApiResponse<object>
            {
                Success = true,
                Message = "Role granted successfully.",
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

    public async Task<ApiResponse<object>> RevokeRoleFromUserAsync(
        string username,
        string roleCode,
        CancellationToken cancellationToken = default)
    {
        try
        {
            await using var userIdCommand = new NpgsqlCommand(
                """
                SELECT user_id FROM university.app_users WHERE lower(username) = lower($1)
                """,
                _transaction.Connection,
                _transaction.Transaction);
            userIdCommand.Parameters.AddWithValue(username.Trim());
            var userId = await userIdCommand.ExecuteScalarAsync(cancellationToken);
            if (userId is null or DBNull)
            {
                return new ApiResponse<object>
                {
                    Success = false,
                    Message = $"User '{username}' not found.",
                    Data = null
                };
            }

            await using var roleIdCommand = new NpgsqlCommand(
                """
                SELECT role_id FROM university.roles WHERE role_code = $1
                """,
                _transaction.Connection,
                _transaction.Transaction);
            roleIdCommand.Parameters.AddWithValue(roleCode.Trim().ToUpperInvariant());
            var roleId = await roleIdCommand.ExecuteScalarAsync(cancellationToken);
            if (roleId is null or DBNull)
            {
                return new ApiResponse<object>
                {
                    Success = false,
                    Message = $"Role '{roleCode}' not found.",
                    Data = null
                };
            }

            const string sql = """
                DELETE FROM university.app_user_roles
                WHERE user_id = $1 AND role_id = $2
                """;

            await using var command = new NpgsqlCommand(
                sql,
                _transaction.Connection,
                _transaction.Transaction);
            command.Parameters.AddWithValue(userId);
            command.Parameters.AddWithValue(roleId);

            await command.ExecuteNonQueryAsync(cancellationToken);

            return new ApiResponse<object>
            {
                Success = true,
                Message = "Role revoked successfully.",
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

    public async Task<ApiResponse<object>> DeleteRoleAsync(
        string roleCode,
        CancellationToken cancellationToken = default)
    {
        try
        {
            const string sql = """
                DELETE FROM university.roles
                WHERE role_code = $1
                """;

            await using var command = new NpgsqlCommand(
                sql,
                _transaction.Connection,
                _transaction.Transaction);
            command.Parameters.AddWithValue(roleCode.Trim().ToUpperInvariant());

            var deleted = await command.ExecuteNonQueryAsync(cancellationToken);
            if (deleted == 0)
            {
                return new ApiResponse<object>
                {
                    Success = false,
                    Message = $"Role '{roleCode}' not found.",
                    Data = null
                };
            }

            return new ApiResponse<object>
            {
                Success = true,
                Message = "Role deleted successfully.",
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
