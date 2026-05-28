using Microsoft.AspNetCore.Mvc;
using UniversityManagementAPI.DTOs.Requests;

[ApiController]
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

}