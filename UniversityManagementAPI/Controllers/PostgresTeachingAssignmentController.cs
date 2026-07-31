using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using UniversityManagementAPI.Repositories.Interfaces;

namespace UniversityManagementAPI.Controllers;

[ApiController]
[Authorize(Roles = "LECTURER,ACADEMIC_AFFAIRS,UNIT_HEAD,DEAN")]
[Route("api/pg/teaching-assignment")]
public sealed class PostgresTeachingAssignmentController : ControllerBase
{
    private readonly IPostgresTeachingAssignmentRepository _assignmentRepository;

    public PostgresTeachingAssignmentController(
        IPostgresTeachingAssignmentRepository assignmentRepository)
    {
        _assignmentRepository = assignmentRepository;
    }

    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<TeachingAssignmentDto>>> GetAll(
        CancellationToken cancellationToken)
    {
        var assignments = await _assignmentRepository.GetAllAsync(cancellationToken);
        return Ok(assignments);
    }

    [Authorize(Roles = "UNIT_HEAD,DEAN")]
    [HttpPost]
    public async Task<IActionResult> Create(
        [FromBody] SaveTeachingAssignmentRequest request,
        CancellationToken cancellationToken)
    {
        await _assignmentRepository.CreateAsync(request, cancellationToken);
        return NoContent();
    }

    [Authorize(Roles = "ACADEMIC_AFFAIRS,UNIT_HEAD,DEAN")]
    [HttpPut]
    public async Task<IActionResult> Update(
        [FromQuery] string originalLecturerId,
        [FromQuery] string originalCourseId,
        [FromQuery] int originalSemester,
        [FromQuery] int originalAcademicYear,
        [FromQuery] string originalProgramId,
        [FromBody] SaveTeachingAssignmentRequest request,
        CancellationToken cancellationToken)
    {
        var original = new TeachingAssignmentDto
        {
            LecturerId = originalLecturerId,
            CourseId = originalCourseId,
            Semester = originalSemester,
            AcademicYear = originalAcademicYear,
            ProgramId = originalProgramId
        };
        var updated = await _assignmentRepository.UpdateAsync(
            original,
            request,
            cancellationToken);
        return updated ? NoContent() : NotFound();
    }

    [Authorize(Roles = "UNIT_HEAD,DEAN")]
    [HttpDelete]
    public async Task<IActionResult> Delete(
        [FromQuery] string lecturerId,
        [FromQuery] string courseId,
        [FromQuery] int semester,
        [FromQuery] int academicYear,
        [FromQuery] string programId,
        CancellationToken cancellationToken)
    {
        var assignment = new TeachingAssignmentDto
        {
            LecturerId = lecturerId,
            CourseId = courseId,
            Semester = semester,
            AcademicYear = academicYear,
            ProgramId = programId
        };
        var deleted = await _assignmentRepository.DeleteAsync(
            assignment,
            cancellationToken);
        return deleted ? NoContent() : NotFound();
    }
}
