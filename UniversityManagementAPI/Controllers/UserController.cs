using Microsoft.AspNetCore.Mvc;
using System.Text.RegularExpressions;
using UniversityManagementAPI.DTOs.Requests;

[ApiController]
[Route("api/user")]
public class UserController : ControllerBase
{
    private const string UsernameValidationMessage = "Username must start with a letter and contain only letters, numbers, _, $, #";

    private readonly IUserService _userService;
    private readonly IUserRepository _userRepository;

    public UserController(IUserService userService, IUserRepository userRepository)
    {
        _userService = userService;
        _userRepository = userRepository;
    }

    private static bool IsValidUsername(string username)
    {
        return Regex.IsMatch(username.Trim(), "^[A-Za-z][A-Za-z0-9_$#]{0,127}$");
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

        if (!IsValidUsername(request.Username))
        {
            return BadRequest(new ApiResponse<object>
            {
                Success = false,
                Message = UsernameValidationMessage,
                Data = null
            });
        }

        var result = await _userService.CreateUser(
            request.Username.Trim().ToUpperInvariant(),
            request.Password);

        if (!result.Success)
        {
            return BadRequest(result);
        }

        return Ok(result);
    }

    [HttpDelete]
    public async Task<IActionResult> DeleteUser([FromBody] DeleteUserRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Username))
        {
            return BadRequest(new ApiResponse<object>
            {
                Success = false,
                Message = "Username are required",
            });
        }

        if (!IsValidUsername(request.Username))
        {
            return BadRequest(new ApiResponse<object>
            {
                Success = false,
                Message = UsernameValidationMessage,
            });
        }

        var result = await _userRepository.DeleteUser(request.Username.Trim().ToUpperInvariant());

        if(!result.Success)
        {
            return BadRequest(result);
        }

        return Ok(result);
    }

    [HttpDelete("{username}")]
    public async Task<IActionResult> DeleteUserByUsername([FromRoute] string username)
    {
        if (string.IsNullOrWhiteSpace(username))
        {
            return BadRequest(new ApiResponse<object>
            {
                Success = false,
                Message = "Username are required",
            });
        }

        if (!IsValidUsername(username))
        {
            return BadRequest(new ApiResponse<object>
            {
                Success = false,
                Message = UsernameValidationMessage,
            });
        }

        var result = await _userRepository.DeleteUser(username.Trim().ToUpperInvariant());

        if(!result.Success)
        {
            return BadRequest(result);
        }

        return Ok(result);
    }

    [HttpPatch("status")]
    [HttpPost("status")]
    [HttpPut("status")]
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

        if (!IsValidUsername(request.Username))
        {
            return BadRequest(new ApiResponse<object>
            {
                Success = false,
                Message = UsernameValidationMessage,
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

        var result = await _userRepository.UpdateUserStatus(request.Username.Trim().ToUpperInvariant(), status);

        if (!result.Success)
        {
            return BadRequest(result);
        }

        return Ok(result);
    }

    [HttpPatch("password")]
    [HttpPost("password")]
    [HttpPut("password")]
    public async Task<IActionResult> UpdateUserPassword([FromBody] UpdateUserPasswordRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Username) || string.IsNullOrWhiteSpace(request.Password))
        {
            return BadRequest(new ApiResponse<object>
            {
                Success = false,
                Message = "Username and password are required",
            });
        }

        if (!IsValidUsername(request.Username))
        {
            return BadRequest(new ApiResponse<object>
            {
                Success = false,
                Message = UsernameValidationMessage,
            });
        }

        var result = await _userRepository.UpdateUserPassword(request.Username.Trim().ToUpperInvariant(), request.Password);

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
