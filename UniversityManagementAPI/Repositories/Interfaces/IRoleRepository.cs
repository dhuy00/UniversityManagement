public interface IRoleRepository
{
    Task<List<RoleDto>> GetAllRolesAsync();
    Task<List<RolePrivilegeDto>> GetRolePrivilege(string rolename);
    Task<ApiResponse<object>> CreateRole(string rolename, string password);
    Task<ApiResponse<object>> UpdateRolePassword(string rolename, string password);
    Task<ApiResponse<object>> GrantRoleToUser(string username, string rolename);
    Task<ApiResponse<object>> RevokeRoleFromUser(string username, string rolename);
    Task<ApiResponse<object>> DeleteRole(string rolename);
    Task<ApiResponse<object>> RevokeRolePrivilege(string rolename, string privilege, string? table_name = null);
}
