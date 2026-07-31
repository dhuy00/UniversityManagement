using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using UniversityManagementAPI.Repositories.Interfaces;

namespace UniversityManagementAPI.Controllers;

[ApiController]
[Authorize]
[Route("api/pg/course")]
public sealed class PostgresCourseController : ControllerBase
{
    private readonly IPostgresCourseRepository _courseRepository;

    public PostgresCourseController(IPostgresCourseRepository courseRepository)
    {
        _courseRepository = courseRepository;
    }

    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<CourseDto>>> GetAll(
        CancellationToken cancellationToken)
    {
        var courses = await _courseRepository.GetAllAsync(cancellationToken);
        return Ok(courses);
    }

    [Authorize(Roles = "ACADEMIC_AFFAIRS")]
    [HttpPost]
    public async Task<IActionResult> Create(
        [FromBody] SaveCourseRequest request,
        CancellationToken cancellationToken)
    {
        await _courseRepository.CreateAsync(request, cancellationToken);
        return NoContent();
    }

    [Authorize(Roles = "ACADEMIC_AFFAIRS")]
    [HttpPut("{courseId}")]
    public async Task<IActionResult> Update(
        [FromRoute] string courseId,
        [FromBody] SaveCourseRequest request,
        CancellationToken cancellationToken)
    {
        var updated = await _courseRepository.UpdateAsync(
            courseId,
            request,
            cancellationToken);

        return updated ? NoContent() : NotFound();
    }
}
