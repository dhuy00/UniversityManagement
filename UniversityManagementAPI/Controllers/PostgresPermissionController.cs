using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using UniversityManagementAPI.DTOs;

namespace UniversityManagementAPI.Controllers;

[ApiController]
[Authorize(Policy = AuthorizationPolicies.SystemAdministrator)]
[Route("api/pg/permission")]
public sealed class PostgresPermissionController : ControllerBase
{
    private readonly IPostgresPermissionRepository _permissionRepository;

    public PostgresPermissionController(IPostgresPermissionRepository permissionRepository)
    {
        _permissionRepository = permissionRepository;
    }

    [HttpGet]
    public async Task<IActionResult> GetAll(CancellationToken cancellationToken)
    {
        var permissions = await _permissionRepository.GetAllPermissionsAsync(cancellationToken);
        return Ok(permissions);
    }

    [HttpGet("role/{roleCode}")]
    public async Task<IActionResult> GetByRole(
        [FromRoute] string roleCode,
        CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(roleCode))
        {
            return BadRequest(new ApiResponse<object>
            {
                Success = false,
                Message = "RoleCode is required.",
                Data = null
            });
        }

        var permissions = await _permissionRepository.GetPermissionsByRoleAsync(roleCode, cancellationToken);
        return Ok(permissions);
    }

    [HttpPost("assign")]
    public async Task<IActionResult> AssignToRole(
        [FromBody] AssignPermissionRequest request,
        CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(request.RoleCode) ||
            string.IsNullOrWhiteSpace(request.PermissionCode))
        {
            return BadRequest(new ApiResponse<object>
            {
                Success = false,
                Message = "RoleCode and PermissionCode are required.",
                Data = null
            });
        }

        var result = await _permissionRepository.AssignPermissionToRoleAsync(
            request.RoleCode,
            request.PermissionCode,
            cancellationToken);

        return result.Success ? Ok(result) : BadRequest(result);
    }

    [HttpPost("revoke")]
    public async Task<IActionResult> RevokeFromRole(
        [FromBody] RevokePermissionRequest request,
        CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(request.RoleCode) ||
            string.IsNullOrWhiteSpace(request.PermissionCode))
        {
            return BadRequest(new ApiResponse<object>
            {
                Success = false,
                Message = "RoleCode and PermissionCode are required.",
                Data = null
            });
        }

        var result = await _permissionRepository.RevokePermissionFromRoleAsync(
            request.RoleCode,
            request.PermissionCode,
            cancellationToken);

        return result.Success ? Ok(result) : BadRequest(result);
    }
}

public class AssignPermissionRequest
{
    public string RoleCode { get; set; } = string.Empty;
    public string PermissionCode { get; set; } = string.Empty;
}

public class RevokePermissionRequest
{
    public string RoleCode { get; set; } = string.Empty;
    public string PermissionCode { get; set; } = string.Empty;
}
