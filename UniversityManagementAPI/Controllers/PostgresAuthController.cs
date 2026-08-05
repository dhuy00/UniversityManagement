using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

[ApiController]
[Route("api/pg/auth")]
public sealed class PostgresAuthController : ControllerBase
{
    private readonly IPostgresLoginService _loginService;

    public PostgresAuthController(IPostgresLoginService loginService)
    {
        _loginService = loginService;
    }

    [AllowAnonymous]
    [HttpPost("login")]
    public async Task<IActionResult> Login(
        [FromBody] PostgresLoginRequest request,
        CancellationToken cancellationToken)
    {
        var result = await _loginService.AuthenticateAsync(
            request.Username,
            request.Password,
            cancellationToken);

        return result is null
            ? Unauthorized(new { message = "Invalid credentials or unsupported account." })
            : Ok(new { token = result.Token, expiresAt = result.ExpiresAt });
    }

    [Authorize]
    [HttpPost("logout")]
    public IActionResult Logout()
    {
        return NoContent();
    }
}
