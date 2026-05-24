using Microsoft.AspNetCore.Mvc;
using UniversityManagementAPI.DTOs.Requests;

[ApiController]
[Route("api/user")]
public class UserController : ControllerBase
{
    private readonly IUserService _userService;

    public UserController(IUserService userService)
    {
        _userService = userService;
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
}