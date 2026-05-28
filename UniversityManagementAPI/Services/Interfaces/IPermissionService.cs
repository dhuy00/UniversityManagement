public interface IPermissionService
{
  Task<ApiResponse<object>> grantPermissionTable(string permission_type, string table_name, string target, int is_grant_option, string[] listColumn);
}