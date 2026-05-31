public interface IRoleRepository
{
    Task<List<RoleDto>> GetAllRolesAsync();
    Task<List<RolePrivilegeDto>> GetRolePrivilege(string rolename);
    Task<ApiResponse<object>> CreateRole(string rolename, string password);
    Task<ApiResponse<object>> GrantRoleToUser(string username, string rolename);
    Task<ApiResponse<object>> DeleteRole(string rolename);
}