using Microsoft.AspNetCore.Mvc;
using UniversityManagementAPI.DTOs.Requests;

[ApiController]
[Route("api/role")]
public class RoleController : ControllerBase
{
    private readonly IRoleService _roleService;
    private readonly IRoleRepository _roleRepository;

    public RoleController(IRoleService roleService, IRoleRepository roleRepository)
    {
        _roleService = roleService;
        _roleRepository = roleRepository;
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

    [HttpPost]
    public async Task<IActionResult> CreateRole([FromBody] CreateRoleRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Rolename) || string.IsNullOrWhiteSpace(request.Password))
        {
            return BadRequest(new ApiResponse<object>
            {
                Success = false,
                Message = "Rolename and password are required",
            });
        }

        var result = await _roleRepository.CreateRole(request.Rolename, request.Password);

        if(!result.Success)
        {
            return BadRequest(result);
        }

        return Ok(result);
    }

    [HttpPost("grant")]
    public async Task<IActionResult> GrantRoleToUser([FromBody] GrantRoleRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Username) || string.IsNullOrWhiteSpace(request.Rolename))
        {
            return BadRequest(new ApiResponse<object>
            {
                Success = false,
                Message = "Username and Rolename are required",
            });
        }

        var result = await _roleRepository.GrantRoleToUser(request.Username, request.Rolename);

        if(!result.Success)
        {
            return BadRequest(result);
        }

        return Ok(result);
    }

    [HttpDelete]
    public async Task<IActionResult> DeleteRole([FromBody] DeleteRoleRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Rolename))
        {
            return BadRequest(new ApiResponse<object>
            {
                Success = false,
                Message = "Rolename are required",
            });
        }

        var result = await _roleRepository.DeleteRole(request.Rolename);

        if(!result.Success)
        {
            return BadRequest(result);
        }

        return Ok(result);
    }

    [HttpPost("revoke-privilege")]
    public async Task<IActionResult> RevokeRolePrivilege([FromBody] RevokeRolePrivilegeRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Rolename))
        {
            return BadRequest(new ApiResponse<object>
            {
                Success = false,
                Message = "Rolename are required",
            });
        }

        if (request.Privilege.Length == 0 || request.Privilege == null)
        {
            return BadRequest(new ApiResponse<object>
            {
                Success = false,
                Message = "At least one privilege is required",
            });
        }

        ApiResponse<object> result;
        string transformPrivilege = _roleService.TransformPrivileges(request.Privilege);

        if(request.TableName != null && request.TableName != "")
        {
            result = await _roleRepository.RevokeRolePrivilege(request.Rolename, transformPrivilege, request.TableName);
        }
        else
        {
            result = await _roleRepository.RevokeRolePrivilege(request.Rolename, transformPrivilege);
        }

        if(!result.Success)
        {
            return BadRequest(result);
        }

        return Ok(result);
    }
}