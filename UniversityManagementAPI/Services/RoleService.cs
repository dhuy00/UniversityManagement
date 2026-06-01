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

    public async Task<ApiResponse<object>> CreateRole(string rolename, string password)
    {
        return await _roleRepository.CreateRole(rolename, password);
    }

    public string TransformPrivileges(string[] privileges)
    {
        if (privileges == null || privileges.Length == 0)
        {
            throw new ArgumentException("At least one privilege is required.", nameof(privileges));
        }

        return string.Join(", ", privileges);
    }
}