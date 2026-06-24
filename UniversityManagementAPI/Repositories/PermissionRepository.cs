using Oracle.ManagedDataAccess.Client;
using System.Data;

public class PermissionRepository : IPermissionRepository
{
  private readonly IDbConnectionFactory _connectionFactory;

  public PermissionRepository(IDbConnectionFactory connectionFactory)
  {
    _connectionFactory = connectionFactory;
  }

  public async Task<List<TableMetadataDto>> GetTablesAsync()
  {
    using var connection = _connectionFactory.CreateConnection();
    await connection.OpenAsync();

    var tables = await ReadTableMetadataAsync(connection, @"
      SELECT
        t.OWNER,
        t.TABLE_NAME,
        c.COLUMN_NAME,
        c.COLUMN_ID
      FROM SYS.DBA_TABLES t
      JOIN SYS.DBA_USERS u
        ON u.USERNAME = t.OWNER
      JOIN SYS.DBA_TAB_COLUMNS c
        ON c.OWNER = t.OWNER
       AND c.TABLE_NAME = t.TABLE_NAME
      WHERE u.ORACLE_MAINTAINED = 'N'
      ORDER BY t.OWNER, t.TABLE_NAME, c.COLUMN_ID");

    if (tables.Count > 0)
    {
      return tables;
    }

    return await ReadTableMetadataAsync(connection, @"
      SELECT
        t.OWNER,
        t.TABLE_NAME,
        c.COLUMN_NAME,
        c.COLUMN_ID
      FROM SYS.DBA_TABLES t
      JOIN SYS.DBA_TAB_COLUMNS c
        ON c.OWNER = t.OWNER
       AND c.TABLE_NAME = t.TABLE_NAME
      WHERE t.OWNER NOT IN (
        'SYS',
        'SYSTEM',
        'XDB',
        'CTXSYS',
        'MDSYS',
        'ORDSYS',
        'OUTLN',
        'WMSYS',
        'DBSNMP',
        'APPQOSSYS',
        'GSMADMIN_INTERNAL'
      )
        AND t.TABLE_NAME NOT LIKE 'BIN$%'
        AND t.NESTED = 'NO'
      ORDER BY t.OWNER, t.TABLE_NAME, c.COLUMN_ID");
  }

  private static async Task<List<TableMetadataDto>> ReadTableMetadataAsync(IDbConnection connection, string sql)
  {
    var tables = new Dictionary<string, TableMetadataDto>();

    using var command = new OracleCommand(sql, (OracleConnection)connection);

    using var reader = await command.ExecuteReaderAsync();

    while (await reader.ReadAsync())
    {
      var owner = reader["OWNER"].ToString()!;
      var tableName = reader["TABLE_NAME"].ToString()!;
      var key = $"{owner}.{tableName}";

      if (!tables.TryGetValue(key, out var table))
      {
        table = new TableMetadataDto
        {
          Owner = owner,
          TableName = tableName,
          Columns = []
        };
        tables[key] = table;
      }

      table.Columns.Add(reader["COLUMN_NAME"].ToString()!);
    }

    return tables.Values.ToList();
  }

  public async Task<List<string>> GetSystemPrivilegesAsync()
  {
    var privileges = new List<string>();

    using var connection = _connectionFactory.CreateConnection();
    await connection.OpenAsync();

    using var command = new OracleCommand(@"
      SELECT REPLACE(NAME, ' ', '_') AS PRIVILEGE_NAME
      FROM SYS.SYSTEM_PRIVILEGE_MAP
      ORDER BY NAME", connection);

    using var reader = await command.ExecuteReaderAsync();

    while (await reader.ReadAsync())
    {
      privileges.Add(reader["PRIVILEGE_NAME"].ToString()!);
    }

    return privileges;
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

  public async Task<ApiResponse<object>> GrantSystemPrivilege(string privilegeName, string target)
  {
    try
    {
      using var connection = _connectionFactory.CreateConnection();
      await connection.OpenAsync();

      using var command = new OracleCommand("PERMISSION_GRANT_SYSTEM", connection);
      command.CommandType = CommandType.StoredProcedure;

      command.Parameters.Add("p_privilege_name", OracleDbType.Varchar2).Value = privilegeName;
      command.Parameters.Add("p_target_name", OracleDbType.Varchar2).Value = target;

      await command.ExecuteNonQueryAsync();

      return new ApiResponse<object>
      {
        Success = true,
        Message = "System privilege granted successfully",
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
