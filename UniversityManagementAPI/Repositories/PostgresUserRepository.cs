using Npgsql;
using UniversityManagementAPI.DTOs.Requests;
using UniversityManagementAPI.Repositories.Interfaces;

namespace UniversityManagementAPI.Repositories;

public sealed class PostgresUserRepository : IPostgresUserRepository
{
    private readonly IPostgresRequestTransaction _transaction;

    public PostgresUserRepository(IPostgresRequestTransaction transaction)
    {
        _transaction = transaction;
    }

    public async Task<PagedResult<UserDto>> GetPageAsync(
        int page,
        int pageSize,
        string? search,
        CancellationToken cancellationToken = default)
    {
        var normalizedSearch = string.IsNullOrWhiteSpace(search) ? null : search.Trim();
        var offset = (page - 1) * pageSize;
        var searchParamIndex = normalizedSearch is not null ? 1 : 0;
        var searchClause = normalizedSearch is null
            ? string.Empty
            : $"""
              WHERE lower(username) LIKE lower('%' || ${searchParamIndex} || '%')
              """;

        await using var countCommand = new NpgsqlCommand(
            $"""
             SELECT COUNT(*)
             FROM university.app_users
             {searchClause}
             """,
            _transaction.Connection,
            _transaction.Transaction);
        if (normalizedSearch is not null)
        {
            countCommand.Parameters.AddWithValue(normalizedSearch);
        }

        var totalItems = Convert.ToInt32(
            await countCommand.ExecuteScalarAsync(cancellationToken));

        await using var command = new NpgsqlCommand(
            $"""
             SELECT
                 u.user_id,
                 u.username,
                 COALESCE(rp.role_code, ss.primary_role) AS role,
                 CASE WHEN u.is_active THEN 'OPEN' ELSE 'EXPIRED' END AS status,
                 u.is_active,
                 u.created_at,
                 u.last_login
             FROM university.app_users u
             LEFT JOIN university.app_user_roles aur ON u.user_id = aur.user_id
             LEFT JOIN university.roles r ON aur.role_id = r.role_id
             LEFT JOIN LATERAL (
                 SELECT aur2.role_code
                 FROM university.app_user_roles aur2
                 JOIN university.roles r2 ON aur2.role_id = r2.role_id
                 WHERE aur2.user_id = u.user_id
                 ORDER BY
                     CASE r2.role_code
                         WHEN 'DEAN'              THEN 1
                         WHEN 'UNIT_HEAD'         THEN 2
                         WHEN 'ACADEMIC_AFFAIRS'  THEN 3
                         WHEN 'LECTURER'          THEN 4
                         WHEN 'BASIC_STAFF'       THEN 5
                         WHEN 'STUDENT'           THEN 6
                         ELSE 99
                     END
                 LIMIT 1
             ) ss ON true
             LEFT JOIN university.role_permissions rp ON r.role_id = rp.role_id
             {searchClause}
             ORDER BY u.user_id
             LIMIT ${searchParamIndex + 1} OFFSET ${searchParamIndex + 2}
             """,
            _transaction.Connection,
            _transaction.Transaction);
        if (normalizedSearch is not null)
        {
            command.Parameters.AddWithValue(normalizedSearch);
        }
        command.Parameters.AddWithValue(pageSize);
        command.Parameters.AddWithValue(offset);

        var users = new List<UserDto>();
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            users.Add(new UserDto
            {
                UserId = reader.GetInt64(0).ToString(),
                Username = reader.GetString(1),
                Role = reader.IsDBNull(2) ? string.Empty : reader.GetString(2),
                Status = reader.GetString(3),
                LastLogin = reader.IsDBNull(7) ? null : reader.GetDateTime(7),
            });
        }

        return new PagedResult<UserDto>(users, page, pageSize, totalItems);
    }

    public async Task<ApiResponse<object>> CreateUserAsync(
        CreateUserRequest request,
        CancellationToken cancellationToken = default)
    {
        try
        {
            var passwordHash = BCrypt.Net.BCrypt.HashPassword(request.Password);

            const string sql = """
                INSERT INTO university.app_users (username, password_hash, is_active)
                VALUES ($1, $2, true)
                ON CONFLICT (username) DO NOTHING
                """;

            await using var command = new NpgsqlCommand(
                sql,
                _transaction.Connection,
                _transaction.Transaction);
            command.Parameters.AddWithValue(request.Username.Trim().ToUpperInvariant());
            command.Parameters.AddWithValue(passwordHash);

            var inserted = await command.ExecuteNonQueryAsync(cancellationToken);
            if (inserted == 0)
            {
                return new ApiResponse<object>
                {
                    Success = false,
                    Message = $"User '{request.Username}' already exists.",
                    Data = null
                };
            }

            return new ApiResponse<object>
            {
                Success = true,
                Message = "User created successfully.",
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

    public async Task<ApiResponse<object>> UpdateUserStatusAsync(
        string username,
        bool isActive,
        CancellationToken cancellationToken = default)
    {
        try
        {
            const string sql = """
                UPDATE university.app_users
                SET is_active = $1
                WHERE lower(username) = lower($2)
                """;

            await using var command = new NpgsqlCommand(
                sql,
                _transaction.Connection,
                _transaction.Transaction);
            command.Parameters.AddWithValue(isActive);
            command.Parameters.AddWithValue(username.Trim());

            var updated = await command.ExecuteNonQueryAsync(cancellationToken);
            if (updated == 0)
            {
                return new ApiResponse<object>
                {
                    Success = false,
                    Message = $"User '{username}' not found.",
                    Data = null
                };
            }

            return new ApiResponse<object>
            {
                Success = true,
                Message = "User status updated successfully.",
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

    public async Task<ApiResponse<object>> UpdateUserPasswordAsync(
        string username,
        string newPasswordHash,
        CancellationToken cancellationToken = default)
    {
        try
        {
            const string sql = """
                UPDATE university.app_users
                SET password_hash = $1
                WHERE lower(username) = lower($2)
                """;

            await using var command = new NpgsqlCommand(
                sql,
                _transaction.Connection,
                _transaction.Transaction);
            command.Parameters.AddWithValue(newPasswordHash);
            command.Parameters.AddWithValue(username.Trim());

            var updated = await command.ExecuteNonQueryAsync(cancellationToken);
            if (updated == 0)
            {
                return new ApiResponse<object>
                {
                    Success = false,
                    Message = $"User '{username}' not found.",
                    Data = null
                };
            }

            return new ApiResponse<object>
            {
                Success = true,
                Message = "User password updated successfully.",
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

    public async Task<ApiResponse<object>> DeleteUserAsync(
        string username,
        CancellationToken cancellationToken = default)
    {
        try
        {
            await using var checkCommand = new NpgsqlCommand(
                """
                SELECT user_id FROM university.app_users WHERE lower(username) = lower($1)
                """,
                _transaction.Connection,
                _transaction.Transaction);
            checkCommand.Parameters.AddWithValue(username.Trim());

            var userId = await checkCommand.ExecuteScalarAsync(cancellationToken);
            if (userId is null or DBNull)
            {
                return new ApiResponse<object>
                {
                    Success = false,
                    Message = $"User '{username}' not found.",
                    Data = null
                };
            }

            const string sql = """
                DELETE FROM university.app_users
                WHERE lower(username) = lower($1)
                """;

            await using var command = new NpgsqlCommand(
                sql,
                _transaction.Connection,
                _transaction.Transaction);
            command.Parameters.AddWithValue(username.Trim());

            await command.ExecuteNonQueryAsync(cancellationToken);

            return new ApiResponse<object>
            {
                Success = true,
                Message = "User deleted successfully.",
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
