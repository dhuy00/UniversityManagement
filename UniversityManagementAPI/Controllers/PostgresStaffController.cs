using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using UniversityManagementAPI.Repositories.Interfaces;

namespace UniversityManagementAPI.Controllers;

[ApiController]
[Authorize(Roles = "DEAN")]
[Route("api/pg/staff")]
public sealed class PostgresStaffController : ControllerBase
{
    private readonly IPostgresStaffRepository _staffRepository;

    public PostgresStaffController(IPostgresStaffRepository staffRepository)
    {
        _staffRepository = staffRepository;
    }

    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<StaffDto>>> GetAll(
        CancellationToken cancellationToken) =>
        Ok(await _staffRepository.GetAllAsync(cancellationToken));

    [HttpPost]
    public async Task<IActionResult> Create(
        [FromBody] CreateStaffRequest request,
        CancellationToken cancellationToken)
    {
        await _staffRepository.CreateAsync(request, cancellationToken);
        return NoContent();
    }

    [HttpPut("{staffId}")]
    public async Task<IActionResult> Update(
        [FromRoute] string staffId,
        [FromBody] UpdateStaffRequest request,
        CancellationToken cancellationToken)
    {
        var updated = await _staffRepository.UpdateAsync(
            staffId,
            request,
            cancellationToken);
        return updated ? NoContent() : NotFound();
    }

    [HttpDelete("{staffId}")]
    public async Task<IActionResult> Delete(
        [FromRoute] string staffId,
        CancellationToken cancellationToken)
    {
        var deleted = await _staffRepository.DeleteAsync(staffId, cancellationToken);
        return deleted ? NoContent() : NotFound();
    }
}
