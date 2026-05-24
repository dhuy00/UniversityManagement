public class RoleService : IRoleService
{
    private readonly IRoleRepository _roleRepository;

    public RoleService(IRoleRepository roleRepository)
    {
        _roleRepository = roleRepository;
    }

    public async Task<List<RoleDto>> GetAllRolesAsync()
    {
        // business logic
        var roles = await _roleRepository.GetAllRolesAsync();

        return roles;
    }

    public async Task<List<RolePrivilegeDto>> GetRolePrivilege(string rolename)
    {
        var privileges = await _roleRepository.GetRolePrivilege(rolename);

        return privileges;
    }
}