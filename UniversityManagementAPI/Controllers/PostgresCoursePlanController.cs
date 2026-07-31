using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using UniversityManagementAPI.Repositories.Interfaces;

namespace UniversityManagementAPI.Controllers;

[ApiController]
[Authorize]
[Route("api/pg/course-plan")]
public sealed class PostgresCoursePlanController : ControllerBase
{
    private readonly IPostgresCoursePlanRepository _coursePlanRepository;

    public PostgresCoursePlanController(IPostgresCoursePlanRepository coursePlanRepository)
    {
        _coursePlanRepository = coursePlanRepository;
    }

    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<CoursePlanDto>>> GetAll(
        CancellationToken cancellationToken)
    {
        var plans = await _coursePlanRepository.GetAllAsync(cancellationToken);
        return Ok(plans);
    }

    [Authorize(Roles = "ACADEMIC_AFFAIRS")]
    [HttpPost]
    public async Task<IActionResult> Create(
        [FromBody] SaveCoursePlanRequest request,
        CancellationToken cancellationToken)
    {
        await _coursePlanRepository.CreateAsync(request, cancellationToken);
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
        var updated = await _coursePlanRepository.UpdateAsync(
            courseId,
            semester,
            academicYear,
            programId,
            request,
            cancellationToken);

        return updated ? NoContent() : NotFound();
    }
}
