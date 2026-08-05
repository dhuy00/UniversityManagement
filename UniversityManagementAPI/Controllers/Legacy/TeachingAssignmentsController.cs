using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

[ApiController]
[Authorize(Roles = "LECTURER,ACADEMIC_AFFAIRS,UNIT_HEAD,DEAN")]
[Route("api/teaching-assignments")]
public sealed class TeachingAssignmentsController : ControllerBase
{
    private readonly ITeachingAssignmentService _assignmentService;

    public TeachingAssignmentsController(
        ITeachingAssignmentService assignmentService)
    {
        _assignmentService = assignmentService;
    }

    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<TeachingAssignmentDto>>> GetAll(
        CancellationToken cancellationToken)
    {
        var assignments = await _assignmentService.GetAllAsync(cancellationToken);
        return Ok(assignments);
    }

    [Authorize(Roles = "UNIT_HEAD,DEAN")]
    [HttpPost]
    public async Task<IActionResult> Create(
        [FromBody] SaveTeachingAssignmentRequest request,
        CancellationToken cancellationToken)
    {
        await _assignmentService.CreateAsync(request, cancellationToken);
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
        var updated = await _assignmentService.UpdateAsync(
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
        var deleted = await _assignmentService.DeleteAsync(
            assignment,
            cancellationToken);
        return deleted ? NoContent() : NotFound();
    }
}
