using Microsoft.AspNetCore.Mvc;
using UniversityManagementAPI.DTOs.Requests;

[ApiController]
[Route("api/user")]
public class UserController : ControllerBase
{
    private readonly IUserService _userService;
    private readonly IUserRepository _userRepository;

    public UserController(IUserService userService, IUserRepository userRepository)
    {
        _userService = userService;
        _userRepository = userRepository;
    }

    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var users = await _userService.GetAllUsersAsync();
        return Ok(users);
    }

    [HttpGet("privilege/{username}")]
    public async Task<IActionResult> GetUserPrivilege([FromRoute] string username)
    {
        var privileges = await _userService.GetUserPrivilege(username);
        return Ok(privileges);
    }

    [HttpPost]
    public async Task<IActionResult> CreateUser(
    [FromBody] CreateUserRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Username) ||
            string.IsNullOrWhiteSpace(request.Password))
        {
            return BadRequest(new ApiResponse<object>
            {
                Success = false,
                Message = "Username and password are required",
                Data = null
            });
        }

        var result = await _userService.CreateUser(
            request.Username,
            request.Password);

        if (!result.Success)
        {
            return BadRequest(result);
        }

        return Ok(result);
    }

    [HttpDelete]
    public async Task<IActionResult> DeleteRole([FromBody] DeleteUserRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Username))
        {
            return BadRequest(new ApiResponse<object>
            {
                Success = false,
                Message = "Username are required",
            });
        }

        var result = await _userRepository.DeleteUser(request.Username);

        if(!result.Success)
        {
            return BadRequest(result);
        }

        return Ok(result);
    }

    [HttpPatch("status")]
    public async Task<IActionResult> UpdateUserStatus([FromBody] UpdateUserStatusRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Username) || string.IsNullOrWhiteSpace(request.Status))
        {
            return BadRequest(new ApiResponse<object>
            {
                Success = false,
                Message = "Username and status are required",
            });
        }

        var status = request.Status.Trim().ToUpperInvariant();
        if (status != "OPEN" && status != "LOCKED")
        {
            return BadRequest(new ApiResponse<object>
            {
                Success = false,
                Message = "Status must be OPEN or LOCKED",
            });
        }

        var result = await _userRepository.UpdateUserStatus(request.Username, status);

        if (!result.Success)
        {
            return BadRequest(result);
        }

        return Ok(result);
    }

    [HttpPost("revoke-privilege")]
    public async Task<IActionResult> RevokeUserPrivilege([FromBody] RevokeUserPrivilegeRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Username))
        {
            return BadRequest(new ApiResponse<object>
            {
                Success = false,
                Message = "Username are required",
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
        string transformPrivilege = _userService.TransformPrivileges(request.Privilege);

        if(request.TableName != null && request.TableName != "")
        {
            result = await _userRepository.RevokeUserPrivilege(request.Username, transformPrivilege, request.TableName);
        }
        else
        {
            result = await _userRepository.RevokeUserPrivilege(request.Username, transformPrivilege);
        }

        if(!result.Success)
        {
            return BadRequest(result);
        }

        return Ok(result);
    }
}
