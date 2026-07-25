public interface IPostgresPermissionRepository
{
    Task<List<PermissionDto>> GetAllPermissionsAsync(CancellationToken cancellationToken = default);
    Task<List<PermissionDto>> GetPermissionsByRoleAsync(
        string roleCode,
        CancellationToken cancellationToken = default);
    Task<ApiResponse<object>> AssignPermissionToRoleAsync(
        string roleCode,
        string permissionCode,
        CancellationToken cancellationToken = default);
    Task<ApiResponse<object>> RevokePermissionFromRoleAsync(
        string roleCode,
        string permissionCode,
        CancellationToken cancellationToken = default);
}
