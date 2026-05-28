using System.Runtime.CompilerServices;

public interface IPermissionRepository
{
  Task<ApiResponse<object>> grantPermissionTable(string permission_type, string table_name, string target, int is_grant_option, string listColumnString);
}
