public interface IRoleService
{
    Task<List<RoleDto>> GetAllRolesAsync();
    Task<List<RolePrivilegeDto>> GetRolePrivilege(string rolename);
    Task<ApiResponse<object>> CreateRole(string rolename, string password);
    string TransformPrivileges(string[] privileges);
}