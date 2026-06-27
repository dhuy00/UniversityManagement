public class PermissionService : IPermissionService
{
  private readonly IPermissionRepository _permissionRepository;

  public PermissionService(IPermissionRepository permissionRepository)
  {
    _permissionRepository = permissionRepository;
  }

  public async Task<ApiResponse<object>> grantPermissionTable(string permission_type, string table_name, string target, int is_grant_option, string[] listColumn)
  {
    string? listColumnString = listColumn == null || listColumn.Length == 0
    ? null
    : string.Join(", ", listColumn);
    return await _permissionRepository.grantPermissionTable(permission_type, table_name, target, is_grant_option, listColumnString);
  }
}
