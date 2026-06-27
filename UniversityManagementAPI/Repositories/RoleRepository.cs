using Oracle.ManagedDataAccess.Client;
using System.Data;

public class RoleRepository : IRoleRepository
{
  private readonly IDbConnectionFactory _connectionFactory;

  public RoleRepository(IDbConnectionFactory connectionFactory)
  {
    _connectionFactory = connectionFactory;
  }

  public async Task<List<RoleDto>> GetAllRolesAsync()
  {
    var roles = new List<RoleDto>();

    using var connection = _connectionFactory.CreateConnection();

    await connection.OpenAsync();

    using var command = new OracleCommand(
        "ROLE_GET_ALL",
        connection);

    command.CommandType = CommandType.StoredProcedure;

    command.Parameters.Add(
        "p_cursor",
        OracleDbType.RefCursor,
        ParameterDirection.Output);

    using var reader = await command.ExecuteReaderAsync();

    while (await reader.ReadAsync())
    {
      roles.Add(new RoleDto
      {
        Role = reader["ROLE"].ToString()!,
        AuthenticationType = reader["AUTHENTICATION_TYPE"].ToString()!,
        Common = reader["COMMON"].ToString()!
      });
    }

    return roles;
  }

  public async Task<List<RolePrivilegeDto>> GetRolePrivilege(string rolename)
  {
    var rolePrivilege = new List<RolePrivilegeDto>();

    using var connection = _connectionFactory.CreateConnection();

    await connection.OpenAsync();

    using var command = new OracleCommand(
        "ROLE_GET_PRIVILEGE",
        connection);

    command.CommandType = CommandType.StoredProcedure;

    command.Parameters.Add("p_rolename", OracleDbType.Varchar2).Value = rolename;

    command.Parameters.Add(
        "p_cursor",
        OracleDbType.RefCursor,
        ParameterDirection.Output);

    using var reader = await command.ExecuteReaderAsync();

    while (await reader.ReadAsync())
    {
      rolePrivilege.Add(new RolePrivilegeDto
      {
        PrivilegeType = reader["PRIVILEGE_TYPE"].ToString()!,
        Role = reader["ROLE"].ToString()!,
        Owner = reader["OWNER"] == DBNull.Value ? string.Empty : reader["OWNER"].ToString()!,
        TableName = reader["TABLE_NAME"] == DBNull.Value ? string.Empty : reader["TABLE_NAME"].ToString()!,
        ColumnName = reader["COLUMN_NAME"] == DBNull.Value ? string.Empty : reader["COLUMN_NAME"].ToString()!,
        Privilege = reader["PRIVILEGE"].ToString()!,
        Grantable = reader["GRANTABLE"].ToString()!,
      });
    }

    return rolePrivilege;
  }

  public async Task<ApiResponse<object>> CreateRole(string rolename, string password)
  {
    try
    {
      using var connection = _connectionFactory.CreateConnection();
      await connection.OpenAsync();

      using var command = new OracleCommand("ROLE_CREATE", connection);
      command.CommandType = CommandType.StoredProcedure;

      command.Parameters.Add("p_rolename", OracleDbType.Varchar2).Value = rolename;
      command.Parameters.Add("p_password", OracleDbType.Varchar2).Value = password;

      await command.ExecuteNonQueryAsync();

      return new ApiResponse<object>
      {
        Success = true,
        Message = "Role created successfully",
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

  public async Task<ApiResponse<object>> GrantRoleToUser(string username, string rolename)
  {
    try
    {
      using var connection = _connectionFactory.CreateConnection();
      await connection.OpenAsync();

      using var command = new OracleCommand("ROLE_GRANT_TO_USER", connection);
      command.CommandType = CommandType.StoredProcedure;

      command.Parameters.Add("p_username", OracleDbType.Varchar2).Value = username;
      command.Parameters.Add("p_rolename", OracleDbType.Varchar2).Value = rolename;

      await command.ExecuteNonQueryAsync();

      return new ApiResponse<object>
      {
        Success = true,
        Message = "Role granted successfully",
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

  public async Task<ApiResponse<object>> UpdateRolePassword(string rolename, string password)
  {
    try
    {
      using var connection = _connectionFactory.CreateConnection();
      await connection.OpenAsync();

      using var command = new OracleCommand("ROLE_UPDATE_PASSWORD", connection);
      command.CommandType = CommandType.StoredProcedure;

      command.Parameters.Add("p_rolename", OracleDbType.Varchar2).Value = rolename;
      command.Parameters.Add("p_password", OracleDbType.Varchar2).Value = password;

      await command.ExecuteNonQueryAsync();

      return new ApiResponse<object>
      {
        Success = true,
        Message = "Role password updated successfully",
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

  public async Task<ApiResponse<object>> DeleteRole(string rolename)
  {
    try
    {
      using var connection = _connectionFactory.CreateConnection();
      await connection.OpenAsync();

      using var command = new OracleCommand("ROLE_DELETE", connection);
      command.CommandType = CommandType.StoredProcedure;

      command.Parameters.Add("p_rolename", OracleDbType.Varchar2).Value = rolename;

      await command.ExecuteNonQueryAsync();

      return new ApiResponse<object>
      {
        Success = true,
        Message = "Role deleted successfully",
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

  public async Task<ApiResponse<object>> RevokeRoleFromUser(string username, string rolename)
  {
    try
    {
      using var connection = _connectionFactory.CreateConnection();
      await connection.OpenAsync();

      using var command = new OracleCommand("ROLE_REVOKE_FROM_USER", connection);
      command.CommandType = CommandType.StoredProcedure;

      command.Parameters.Add("p_username", OracleDbType.Varchar2).Value = username;
      command.Parameters.Add("p_rolename", OracleDbType.Varchar2).Value = rolename;

      await command.ExecuteNonQueryAsync();

      return new ApiResponse<object>
      {
        Success = true,
        Message = "Role revoked successfully",
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

  public async Task<ApiResponse<object>> RevokeRolePrivilege(string rolename, string privilege, string? table_name = null)
  {
    try
    {
      using var connection = _connectionFactory.CreateConnection();
      await connection.OpenAsync();

      using var command = new OracleCommand("ROLE_REVOKE_PRIVILEGE", connection);
      command.CommandType = CommandType.StoredProcedure;

      command.Parameters.Add("p_username", OracleDbType.Varchar2).Value = rolename;
      command.Parameters.Add("p_privileges", OracleDbType.Varchar2).Value = privilege;
      if(table_name != null)
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
