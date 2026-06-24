using Oracle.ManagedDataAccess.Client;
using System.Data;
using BCrypt.Net;

public class UserRepository : IUserRepository
{
  private readonly IDbConnectionFactory _connectionFactory;

  public UserRepository(IDbConnectionFactory connectionFactory)
  {
    _connectionFactory = connectionFactory;
  }

  public async Task<List<UserDto>> GetAllUsersAsync()
  {
    var users = new List<UserDto>();

    using var connection = _connectionFactory.CreateConnection();

    await connection.OpenAsync();

    using var command = new OracleCommand(
        "USER_GET_ALL",
        connection);

    command.CommandType = CommandType.StoredProcedure;

    command.Parameters.Add(
        "p_cursor",
        OracleDbType.RefCursor,
        ParameterDirection.Output);

    using var reader = await command.ExecuteReaderAsync();

    while (await reader.ReadAsync())
    {
      users.Add(new UserDto
      {
        Username = reader["USERNAME"].ToString()!,
        Role = reader["ROLE"].ToString()!,
        Status = reader["ACCOUNT_STATUS"].ToString()!,
        UserId = reader["USER_ID"].ToString()!,
        LastLogin = reader["LAST_LOGIN"] == DBNull.Value
        ? null
        : ((DateTimeOffset)reader["LAST_LOGIN"]).LocalDateTime,
      });
    }

    return users;
  }

  public async Task<List<UserPrivilegeDto>> GetUserPrivilege(string username)
  {
    var userPrivilege = new List<UserPrivilegeDto>();

    using var connection = _connectionFactory.CreateConnection();

    await connection.OpenAsync();

    using var command = new OracleCommand(
        "USER_GET_PRIVILEGE",
        connection);

    command.CommandType = CommandType.StoredProcedure;

    command.Parameters.Add("p_username", OracleDbType.Varchar2).Value = username;

    command.Parameters.Add(
        "p_cursor",
        OracleDbType.RefCursor,
        ParameterDirection.Output);

    using var reader = await command.ExecuteReaderAsync();

    while (await reader.ReadAsync())
    {
      userPrivilege.Add(new UserPrivilegeDto
      {
        PrivilegeType = reader["PRIVILEGE_TYPE"].ToString()!,
        Grantee = reader["GRANTEE"].ToString()!,
        Owner = reader["OWNER"] == DBNull.Value ? string.Empty : reader["OWNER"].ToString()!,
        TableName = reader["TABLE_NAME"] == DBNull.Value ? string.Empty : reader["TABLE_NAME"].ToString()!,
        ColumnName = reader["COLUMN_NAME"] == DBNull.Value ? string.Empty : reader["COLUMN_NAME"].ToString()!,
        Privilege = reader["PRIVILEGE"].ToString()!,
        Grantable = reader["GRANTABLE"].ToString()!,
      });
    }

    return userPrivilege;
  }

  public async Task<ApiResponse<object>> CreateUser(string username, string password)
  {
    try
    {
      using var connection = _connectionFactory.CreateConnection();

      await connection.OpenAsync();

      using var command = new OracleCommand(
          "USER_CREATE",
          connection);

      command.CommandType = CommandType.StoredProcedure;

      command.Parameters.Add(
          "p_username",
          OracleDbType.Varchar2).Value = username;

      command.Parameters.Add(
          "p_password",
          OracleDbType.Varchar2).Value = password;

      await command.ExecuteNonQueryAsync();

      return new ApiResponse<object>
      {
        Success = true,
        Message = "User created successfully",
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

  public async Task<ApiResponse<object>> DeleteUser(string username)
  {
    try
    {
      using var connection = _connectionFactory.CreateConnection();
      await connection.OpenAsync();

      using var command = new OracleCommand("USER_DELETE", connection);
      command.CommandType = CommandType.StoredProcedure;

      command.Parameters.Add("p_username", OracleDbType.Varchar2).Value = username;

      await command.ExecuteNonQueryAsync();

      return new ApiResponse<object>
      {
        Success = true,
        Message = "User deleted successfully",
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

  public async Task<ApiResponse<object>> UpdateUserStatus(string username, string status)
  {
    try
    {
      using var connection = _connectionFactory.CreateConnection();
      await connection.OpenAsync();

      using var command = new OracleCommand("USER_UPDATE_STATUS", connection);
      command.CommandType = CommandType.StoredProcedure;

      command.Parameters.Add("p_username", OracleDbType.Varchar2).Value = username;
      command.Parameters.Add("p_status", OracleDbType.Varchar2).Value = status;

      await command.ExecuteNonQueryAsync();

      return new ApiResponse<object>
      {
        Success = true,
        Message = "User status updated successfully",
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

  public async Task<ApiResponse<object>> UpdateUserPassword(string username, string password)
  {
    try
    {
      using var connection = _connectionFactory.CreateConnection();
      await connection.OpenAsync();

      using var command = new OracleCommand("USER_UPDATE_PASSWORD", connection);
      command.CommandType = CommandType.StoredProcedure;

      command.Parameters.Add("p_username", OracleDbType.Varchar2).Value = username;
      command.Parameters.Add("p_password", OracleDbType.Varchar2).Value = password;

      await command.ExecuteNonQueryAsync();

      return new ApiResponse<object>
      {
        Success = true,
        Message = "User password updated successfully",
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

  public async Task<ApiResponse<object>> RevokeUserPrivilege(string username, string privilege, string? table_name = null)
  {
    try
    {
      using var connection = _connectionFactory.CreateConnection();
      await connection.OpenAsync();

      using var command = new OracleCommand("USER_REVOKE_PRIVILEGE", connection);
      command.CommandType = CommandType.StoredProcedure;

      command.Parameters.Add("p_username", OracleDbType.Varchar2).Value = username;
      command.Parameters.Add("p_privileges", OracleDbType.Varchar2).Value = privilege;
      if (table_name != null)
      {
        command.Parameters.Add("p_table_name", OracleDbType.Varchar2).Value = table_name;
      }

      await command.ExecuteNonQueryAsync();

      return new ApiResponse<object>
      {
        Success = true,
        Message = "Privilege revoked successfully",
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
