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
}
