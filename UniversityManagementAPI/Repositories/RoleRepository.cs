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
        Role = reader["ROLE"].ToString()!,
        Owner = reader["OWNER"].ToString()!,
        TableName = reader["TABLE_NAME"].ToString()!,
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
}