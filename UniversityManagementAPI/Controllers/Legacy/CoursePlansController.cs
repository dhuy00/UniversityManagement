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

    [Authorize(Roles = "ACADEMIC_AFFAIRS")]
    [HttpPost]
    public async Task<IActionResult> Create(
        [FromBody] SaveCoursePlanRequest request,
        CancellationToken cancellationToken)
    {
        await _coursePlanService.CreateAsync(request, cancellationToken);
        return NoContent();
    }

    [Authorize(Roles = "ACADEMIC_AFFAIRS")]
    [HttpPut("{courseId}")]
    public async Task<IActionResult> Update(
        [FromRoute] string courseId,
        [FromQuery] int semester,
        [FromQuery] int academicYear,
        [FromQuery] string programId,
        [FromBody] SaveCoursePlanRequest request,
        CancellationToken cancellationToken)
    {
        var updated = await _coursePlanService.UpdateAsync(
            courseId,
            semester,
            academicYear,
            programId,
            request,
            cancellationToken);

        return updated ? NoContent() : NotFound();
    }
}
