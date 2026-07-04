using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

[ApiController]
[Authorize]
[Route("api/profile")]
public sealed class ProfileController : ControllerBase
{
    private readonly IProfileService _profileService;

    public ProfileController(IProfileService profileService)
    {
        _profileService = profileService;
    }

    [HttpGet]
    public async Task<IActionResult> GetCurrent(
        CancellationToken cancellationToken)
    {
        var identityType = User.FindFirst("identity_type")?.Value;
        var identityId = identityType switch
        {
            "STAFF" => User.FindFirst("staff_id")?.Value,
            "STUDENT" => User.FindFirst("student_id")?.Value,
            _ => null
        };

        if (identityType is null || identityId is null)
        {
            return Forbid();
        }

        var profile = await _profileService.GetProfileAsync(
            identityType,
            identityId,
            cancellationToken);

        return profile is null ? NotFound() : Ok(profile);
    }
}
