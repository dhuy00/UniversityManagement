using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using UniversityManagementAPI.DTOs.Requests;

[ApiController]
[Authorize(Policy = AuthorizationPolicies.SystemAdministrator)]
[Route("api/permission")]
public class PermissionController : ControllerBase
{
  private readonly IPermissionService _permissionService;
  private readonly IPermissionRepository _permissionRepository;

  public PermissionController(IPermissionService permissionService, IPermissionRepository permissionRepository)
  {
    _permissionService = permissionService;
    _permissionRepository = permissionRepository;
  }

  [HttpGet("tables")]
  public async Task<IActionResult> GetTables()
  {
    var tables = await _permissionRepository.GetTablesAsync();
    return Ok(tables);
  }

  [HttpGet("system-privileges")]
  public async Task<IActionResult> GetSystemPrivileges()
  {
    var privileges = await _permissionRepository.GetSystemPrivilegesAsync();
    return Ok(privileges);
  }

  [HttpPost]
  public async Task<IActionResult> CreateRole([FromBody] GrantPermissionRequest request)
  {
    var result = await _permissionService.grantPermissionTable(request.PermissionType, request.TableName, request.Target, request.IsGrantOption, request.ListColumn);

    if (!result.Success)
    {
      return BadRequest(result);
    }

    return Ok(result);
  }

  [HttpPost("system")]
  public async Task<IActionResult> GrantSystemPrivilege([FromBody] GrantSystemPrivilegeRequest request)
  {
    if (string.IsNullOrWhiteSpace(request.PrivilegeName) || string.IsNullOrWhiteSpace(request.Target))
    {
      return BadRequest(new ApiResponse<object>
      {
        Success = false,
        Message = "PrivilegeName and Target are required",
      });
    }

    var result = await _permissionRepository.GrantSystemPrivilege(request.PrivilegeName, request.Target);

    if (!result.Success)
    {
      return BadRequest(result);
    }

    return Ok(result);
  }

}
