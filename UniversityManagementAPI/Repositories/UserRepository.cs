using Oracle.ManagedDataAccess.Client;
using System.Data;

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
        Status = reader["ACCOUNT_STATUS"].ToString()!
      });
    }

    return users;
  }

  public async Task<List<UserPrivilegeDto>> GetUserPrivilege(int userId)
  {
    var userPrivilege = new List<UserPrivilegeDto>();

    using var connection = _connectionFactory.CreateConnection();

    await connection.OpenAsync();

    using var command = new OracleCommand(
        "USER_GET_PRIVILEGE",
        connection);

    command.CommandType = CommandType.StoredProcedure;

    command.Parameters.Add("p_user_id", OracleDbType.Int32).Value = userId;

    command.Parameters.Add(
        "p_cursor",
        OracleDbType.RefCursor,
        ParameterDirection.Output);

    using var reader = await command.ExecuteReaderAsync();

    while (await reader.ReadAsync())
    {
      userPrivilege.Add(new UserPrivilegeDto
      {
        Grantee = reader["GRANTEE"].ToString()!,
        Owner = reader["OWNER"].ToString()!,
        TableName = reader["TABLE_NAME"].ToString()!,
        Privilege = reader["PRIVILEGE"].ToString()!,
        Grantable = reader["GRANTABLE"].ToString()!,
      });
    }

    return userPrivilege;
  }
}