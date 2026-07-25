using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using UniversityManagementAPI.DTOs;
using UniversityManagementAPI.DTOs.Requests;

namespace UniversityManagementAPI.Controllers;

[ApiController]
[Authorize(Policy = AuthorizationPolicies.SystemAdministrator)]
[Route("api/pg/role")]
public sealed class PostgresRoleController : ControllerBase
{
    private readonly IPostgresRoleRepository _roleRepository;

    public PostgresRoleController(IPostgresRoleRepository roleRepository)
    {
        _roleRepository = roleRepository;
    }

    [HttpGet]
    public async Task<IActionResult> GetAll(CancellationToken cancellationToken)
    {
        var roles = await _roleRepository.GetAllRolesAsync(cancellationToken);
        return Ok(roles);
    }

    [HttpPost]
    public async Task<IActionResult> CreateRole(
        [FromBody] CreatePostgresRoleRequest request,
        CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(request.RoleCode))
        {
            return BadRequest(new ApiResponse<object>
            {
                Success = false,
                Message = "RoleCode is required.",
                Data = null
            });
        }

        var result = await _roleRepository.CreateRoleAsync(
            request.RoleCode,
            request.Description,
            cancellationToken);

        return result.Success ? Ok(result) : BadRequest(result);
    }

    [HttpPost("grant")]
    public async Task<IActionResult> GrantRoleToUser(
        [FromBody] GrantRoleRequest request,
        CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(request.Username) ||
            string.IsNullOrWhiteSpace(request.Rolename))
        {
            return BadRequest(new ApiResponse<object>
            {
                Success = false,
                Message = "Username and Rolename are required.",
                Data = null
            });
        }

        var result = await _roleRepository.GrantRoleToUserAsync(
            request.Username,
            request.Rolename,
            cancellationToken);

        return result.Success ? Ok(result) : BadRequest(result);
    }

    [HttpPost("revoke")]
    public async Task<IActionResult> RevokeRoleFromUser(
        [FromBody] RevokeRoleFromUserRequest request,
        CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(request.Username) ||
            string.IsNullOrWhiteSpace(request.Rolename))
        {
            return BadRequest(new ApiResponse<object>
            {
                Success = false,
                Message = "Username and Rolename are required.",
                Data = null
            });
        }

        var result = await _roleRepository.RevokeRoleFromUserAsync(
            request.Username,
            request.Rolename,
            cancellationToken);

        return result.Success ? Ok(result) : BadRequest(result);
    }

    [HttpDelete("{roleCode}")]
    public async Task<IActionResult> DeleteRole(
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

        var result = await _roleRepository.DeleteRoleAsync(roleCode, cancellationToken);
        return result.Success ? Ok(result) : BadRequest(result);
    }
}
