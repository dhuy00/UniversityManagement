using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using UniversityManagementAPI.Repositories.Interfaces;

namespace UniversityManagementAPI.Controllers;

[ApiController]
[Authorize]
[Route("api/pg/enrollment")]
public sealed class PostgresEnrollmentController : ControllerBase
{
    private readonly IPostgresEnrollmentRepository _enrollmentRepository;

    public PostgresEnrollmentController(IPostgresEnrollmentRepository enrollmentRepository)
    {
        _enrollmentRepository = enrollmentRepository;
    }

    [Authorize(Roles = "STUDENT,LECTURER,UNIT_HEAD,DEAN")]
    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<EnrollmentDto>>> GetAll(
        CancellationToken cancellationToken)
    {
        var enrollments = await _enrollmentRepository.GetAllAsync(cancellationToken);
        return Ok(enrollments);
    }

    [Authorize(Roles = "STUDENT,LECTURER,UNIT_HEAD,DEAN")]
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
            return BadRequest(new { message = "A valid course plan key is required." });
        }

        var enrollments = await _enrollmentRepository.GetByCoursePlanAsync(
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
        var updated = await _enrollmentRepository.UpdateScoresAsync(
            request,
            cancellationToken);
        return updated ? NoContent() : NotFound();
    }

    [Authorize(Roles = "STUDENT,ACADEMIC_AFFAIRS")]
    [HttpGet("registration-options")]
    public async Task<ActionResult<IReadOnlyList<RegistrationOptionDto>>>
        GetRegistrationOptions(CancellationToken cancellationToken)
    {
        var options = await _enrollmentRepository.GetRegistrationOptionsAsync(cancellationToken);
        return Ok(options);
    }

    [Authorize(Roles = "STUDENT,ACADEMIC_AFFAIRS")]
    [HttpPost]
    public async Task<IActionResult> Create(
        [FromBody] MaintainEnrollmentRequest request,
        CancellationToken cancellationToken)
    {
        await _enrollmentRepository.CreateAsync(request, cancellationToken);
        return NoContent();
    }

    [Authorize(Roles = "STUDENT,ACADEMIC_AFFAIRS")]
    [HttpDelete]
    public async Task<IActionResult> Delete(
        [FromBody] MaintainEnrollmentRequest request,
        CancellationToken cancellationToken)
    {
        var deleted = await _enrollmentRepository.DeleteAsync(
            request,
            cancellationToken);
        return deleted ? NoContent() : NotFound();
    }
}
