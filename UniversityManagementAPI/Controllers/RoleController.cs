using Microsoft.AspNetCore.Mvc;

[ApiController]
[Route("api/role")]
public class RoleController : ControllerBase
{
    private readonly IRoleService _roleService;

    public RoleController(IRoleService roleService)
    {
        _roleService = roleService;
    }

    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var users = await _roleService.GetAllRolesAsync();
        return Ok(users);
    }

    [HttpGet("privilege/{rolename}")]
    public async Task<IActionResult> GetRolePrivilege([FromRoute] string rolename)
    {
        var privileges = await _roleService.GetRolePrivilege(rolename);
        return Ok(privileges);
    }
}