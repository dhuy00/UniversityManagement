using System.Runtime.CompilerServices;

public interface IPermissionRepository
{
  Task<List<TableMetadataDto>> GetTablesAsync();
  Task<List<string>> GetSystemPrivilegesAsync();
  Task<ApiResponse<object>> grantPermissionTable(string permission_type, string table_name, string target, int is_grant_option, string listColumnString);
  Task<ApiResponse<object>> GrantSystemPrivilege(string privilegeName, string target);
}
