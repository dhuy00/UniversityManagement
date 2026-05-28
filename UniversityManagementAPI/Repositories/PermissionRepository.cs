using Oracle.ManagedDataAccess.Client;
using System.Data;

public class PermissionRepository : IPermissionRepository
{
  private readonly IDbConnectionFactory _connectionFactory;

  public PermissionRepository(IDbConnectionFactory connectionFactory)
  {
    _connectionFactory = connectionFactory;
  }

  public async Task<ApiResponse<object>> grantPermissionTable(string permission_type, string table_name, string target, int is_grant_option, string listColumnString)
  {
    try
    {
      using var connection = _connectionFactory.CreateConnection();
      await connection.OpenAsync();

      using var command = new OracleCommand("PERMISSION_GRANT", connection);

      command.CommandType = CommandType.StoredProcedure;

      command.Parameters.Add("p_permission_type", OracleDbType.Varchar2).Value = permission_type;
      command.Parameters.Add("p_tablename", OracleDbType.Varchar2).Value = table_name;
      command.Parameters.Add("p_target_name", OracleDbType.Varchar2).Value = target;
      command.Parameters.Add("p_is_grant_option", OracleDbType.Int32).Value = is_grant_option;
      command.Parameters.Add("p_column_name", OracleDbType.Varchar2).Value = listColumnString;

      await command.ExecuteNonQueryAsync();

      return new ApiResponse<object>
      {
        Success = true,
        Message = "Permission granted successfully",
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