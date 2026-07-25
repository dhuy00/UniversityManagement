public interface IPostgresRoleRepository
{
    Task<List<RoleDto>> GetAllRolesAsync(CancellationToken cancellationToken = default);
    Task<ApiResponse<object>> CreateRoleAsync(
        string roleCode,
        string description,
        CancellationToken cancellationToken = default);
    Task<ApiResponse<object>> GrantRoleToUserAsync(
        string username,
        string roleCode,
        CancellationToken cancellationToken = default);
    Task<ApiResponse<object>> RevokeRoleFromUserAsync(
        string username,
        string roleCode,
        CancellationToken cancellationToken = default);
    Task<ApiResponse<object>> DeleteRoleAsync(
        string roleCode,
        CancellationToken cancellationToken = default);
}
