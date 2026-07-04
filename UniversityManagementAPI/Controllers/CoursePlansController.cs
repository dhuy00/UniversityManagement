using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

[ApiController]
[Authorize]
[Route("api/course-plans")]
public sealed class CoursePlansController : ControllerBase
{
    private readonly ICoursePlanService _coursePlanService;

    public CoursePlansController(ICoursePlanService coursePlanService)
    {
        _coursePlanService = coursePlanService;
    }

    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<CoursePlanDto>>> GetAll(
        CancellationToken cancellationToken)
    {
        var plans = await _coursePlanService.GetAllAsync(cancellationToken);
        return Ok(plans);
    }
}
