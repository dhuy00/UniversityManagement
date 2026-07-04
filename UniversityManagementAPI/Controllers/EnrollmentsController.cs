using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

[ApiController]
[Authorize(Roles = "STUDENT,LECTURER,UNIT_HEAD,DEAN")]
[Route("api/enrollments")]
public sealed class EnrollmentsController : ControllerBase
{
    private readonly IEnrollmentService _enrollmentService;

    public EnrollmentsController(IEnrollmentService enrollmentService)
    {
        _enrollmentService = enrollmentService;
    }

    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<EnrollmentDto>>> GetAll(
        CancellationToken cancellationToken)
    {
        var enrollments = await _enrollmentService.GetAllAsync(cancellationToken);
        return Ok(enrollments);
    }

    [HttpGet("course-plan")]
    public async Task<ActionResult<IReadOnlyList<EnrollmentDto>>> GetByCoursePlan(
        [FromQuery] string courseId,
        [FromQuery] int semester,
        [FromQuery] int academicYear,
        [FromQuery] string programId,
        CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(courseId) ||
            string.IsNullOrWhiteSpace(programId) ||
            semester <= 0 ||
            academicYear <= 0)
        {
            return BadRequest(new
            {
                message = "A valid course plan key is required."
            });
        }

        var enrollments = await _enrollmentService.GetByCoursePlanAsync(
            courseId,
            semester,
            academicYear,
            programId,
            cancellationToken);
        return Ok(enrollments);
    }

    [Authorize(Roles = "LECTURER,UNIT_HEAD,DEAN")]
    [HttpPut("scores")]
    public async Task<IActionResult> UpdateScores(
        [FromBody] UpdateEnrollmentScoresRequest request,
        CancellationToken cancellationToken)
    {
        var updated = await _enrollmentService.UpdateScoresAsync(
            request,
            cancellationToken);

        return updated ? NoContent() : NotFound();
    }
}
