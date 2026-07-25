using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using UniversityManagementAPI.DTOs;
using UniversityManagementAPI.DTOs.Requests;

namespace UniversityManagementAPI.Controllers;

[ApiController]
[Authorize(Policy = AuthorizationPolicies.SystemAdministrator)]
[Route("api/pg/user")]
public sealed class PostgresUserController : ControllerBase
{
    private readonly IPostgresUserRepository _userRepository;

    public PostgresUserController(IPostgresUserRepository userRepository)
    {
        _userRepository = userRepository;
    }

    [HttpGet]
    public async Task<IActionResult> GetPage(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        [FromQuery] string? search = null,
        CancellationToken cancellationToken = default)
    {
        if (page < 1) page = 1;
        if (pageSize < 1) pageSize = 20;
        if (pageSize > 100) pageSize = 100;

        var result = await _userRepository.GetPageAsync(page, pageSize, search, cancellationToken);
        return Ok(result);
    }

    [HttpPost]
    public async Task<IActionResult> CreateUser(
        [FromBody] CreateUserRequest request,
        CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(request.Username) ||
            string.IsNullOrWhiteSpace(request.Password))
        {
            return BadRequest(new ApiResponse<object>
            {
                Success = false,
                Message = "Username and password are required.",
                Data = null
            });
        }

        var result = await _userRepository.CreateUserAsync(request, cancellationToken);
        return result.Success ? Ok(result) : BadRequest(result);
    }

    [HttpDelete("{username}")]
    public async Task<IActionResult> DeleteUser(
        [FromRoute] string username,
        CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(username))
        {
            return BadRequest(new ApiResponse<object>
            {
                Success = false,
                Message = "Username is required.",
                Data = null
            });
        }

        var result = await _userRepository.DeleteUserAsync(username, cancellationToken);
        return result.Success ? Ok(result) : BadRequest(result);
    }

    [HttpPatch("status")]
    public async Task<IActionResult> UpdateUserStatus(
        [FromBody] UpdateUserStatusRequest request,
        CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(request.Username) ||
            string.IsNullOrWhiteSpace(request.Status))
        {
            return BadRequest(new ApiResponse<object>
            {
                Success = false,
                Message = "Username and status are required.",
                Data = null
            });
        }

        var status = request.Status.Trim().ToUpperInvariant();
        if (status != "OPEN" && status != "EXPIRED")
        {
            return BadRequest(new ApiResponse<object>
            {
                Success = false,
                Message = "Status must be OPEN or EXPIRED.",
                Data = null
            });
        }

        var isActive = status == "OPEN";
        var result = await _userRepository.UpdateUserStatusAsync(
            request.Username,
            isActive,
            cancellationToken);

        return result.Success ? Ok(result) : BadRequest(result);
    }

    [HttpPatch("password")]
    public async Task<IActionResult> UpdateUserPassword(
        [FromBody] UpdateUserPasswordRequest request,
        CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(request.Username) ||
            string.IsNullOrWhiteSpace(request.Password))
        {
            return BadRequest(new ApiResponse<object>
            {
                Success = false,
                Message = "Username and password are required.",
                Data = null
            });
        }

        var passwordHash = BCrypt.Net.BCrypt.HashPassword(request.Password);
        var result = await _userRepository.UpdateUserPasswordAsync(
            request.Username,
            passwordHash,
            cancellationToken);

        return result.Success ? Ok(result) : BadRequest(result);
    }
}
