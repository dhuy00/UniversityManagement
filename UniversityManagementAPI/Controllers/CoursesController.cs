using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

[ApiController]
[Authorize]
[Route("api/courses")]
public sealed class CoursesController : ControllerBase
{
    private readonly ICourseService _courseService;

    public CoursesController(ICourseService courseService)
    {
        _courseService = courseService;
    }

    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<CourseDto>>> GetAll(
        CancellationToken cancellationToken)
    {
        var courses = await _courseService.GetAllAsync(cancellationToken);
        return Ok(courses);
    }

    [Authorize(Roles = "ACADEMIC_AFFAIRS")]
    [HttpPost]
    public async Task<IActionResult> Create(
        [FromBody] SaveCourseRequest request,
        CancellationToken cancellationToken)
    {
        await _courseService.CreateAsync(request, cancellationToken);
        return NoContent();
    }

    [Authorize(Roles = "ACADEMIC_AFFAIRS")]
    [HttpPut("{courseId}")]
    public async Task<IActionResult> Update(
        [FromRoute] string courseId,
        [FromBody] SaveCourseRequest request,
        CancellationToken cancellationToken)
    {
        var updated = await _courseService.UpdateAsync(
            courseId,
            request,
            cancellationToken);

        return updated ? NoContent() : NotFound();
    }
}
