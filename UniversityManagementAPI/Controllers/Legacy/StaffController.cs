using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

[ApiController]
[Authorize(Roles = "DEAN")]
[Route("api/staff")]
public sealed class StaffController : ControllerBase
{
    private readonly IStaffService _service;

    public StaffController(IStaffService service)
    {
        _service = service;
    }

    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<StaffDto>>> GetAll(
        CancellationToken cancellationToken) =>
        Ok(await _service.GetAllAsync(cancellationToken));

    [HttpPost]
    public async Task<IActionResult> Create(
        [FromBody] CreateStaffRequest request,
        CancellationToken cancellationToken)
    {
        await _service.CreateAsync(request, cancellationToken);
        return NoContent();
    }

    [HttpPut("{staffId}")]
    public async Task<IActionResult> Update(
        [FromRoute] string staffId,
        [FromBody] UpdateStaffRequest request,
        CancellationToken cancellationToken)
    {
        var updated = await _service.UpdateAsync(
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
        var deleted = await _service.DeleteAsync(staffId, cancellationToken);
        return deleted ? NoContent() : NotFound();
    }
}
