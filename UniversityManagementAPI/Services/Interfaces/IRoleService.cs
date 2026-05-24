public interface IRoleService
{
    Task<List<RoleDto>> GetAllRolesAsync();
    Task<List<RolePrivilegeDto>> GetRolePrivilege(string rolename);
}