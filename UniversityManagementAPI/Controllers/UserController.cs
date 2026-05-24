using Microsoft.AspNetCore.Mvc;

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
}