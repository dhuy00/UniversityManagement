using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using UniversityManagementAPI.DTOs;
using UniversityManagementAPI.Repositories.Interfaces;

namespace UniversityManagementAPI.Controllers;

[ApiController]
[Authorize]
[Route("api/pg/student")]
public sealed class PostgresStudentController : ControllerBase
{
    private readonly IPostgresStudentRepository _studentRepository;

    public PostgresStudentController(IPostgresStudentRepository studentRepository)
    {
        _studentRepository = studentRepository;
    }

    [HttpGet]
    public async Task<ActionResult<PagedResult<StudentDto>>> GetPage(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        [FromQuery] string? search = null,
        CancellationToken cancellationToken = default)
    {
        page = Math.Max(page, 1);
        pageSize = Math.Clamp(pageSize, 1, 100);

        var result = await _studentRepository.GetPageAsync(
            page,
            pageSize,
            search,
            cancellationToken);
        return Ok(result);
    }

    [Authorize(Roles = "ACADEMIC_AFFAIRS")]
    [HttpPost]
    public async Task<IActionResult> Create(
        [FromBody] CreateStudentRequest request,
        CancellationToken cancellationToken)
    {
        await _studentRepository.CreateAsync(request, cancellationToken);
        return NoContent();
    }

    [Authorize(Roles = "ACADEMIC_AFFAIRS")]
    [HttpPut("{studentId}")]
    public async Task<IActionResult> Update(
        [FromRoute] string studentId,
        [FromBody] UpdateStudentRequest request,
        CancellationToken cancellationToken)
    {
        var updated = await _studentRepository.UpdateAsync(
            studentId,
            request,
            cancellationToken);

        return updated ? NoContent() : NotFound();
    }
}
