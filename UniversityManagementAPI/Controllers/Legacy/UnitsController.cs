using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

[ApiController]
[Authorize(Roles = "BASIC_STAFF,LECTURER,ACADEMIC_AFFAIRS,UNIT_HEAD,DEAN")]
[Route("api/units")]
public sealed class UnitsController : ControllerBase
{
    private readonly IUnitService _unitService;

    public UnitsController(IUnitService unitService)
    {
        _unitService = unitService;
    }

    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<UnitDto>>> GetAll(
        CancellationToken cancellationToken)
    {
        var units = await _unitService.GetAllAsync(cancellationToken);
        return Ok(units);
    }

    [Authorize(Roles = "ACADEMIC_AFFAIRS")]
    [HttpPost]
    public async Task<IActionResult> Create(
        [FromBody] CreateUnitRequest request,
        CancellationToken cancellationToken)
    {
        await _unitService.CreateAsync(request, cancellationToken);
        return NoContent();
    }

    [Authorize(Roles = "ACADEMIC_AFFAIRS")]
    [HttpPut("{unitId}")]
    public async Task<IActionResult> Update(
        [FromRoute] string unitId,
        [FromBody] UpdateUnitRequest request,
        CancellationToken cancellationToken)
    {
        var updated = await _unitService.UpdateAsync(
            unitId,
            request,
            cancellationToken);

        return updated ? NoContent() : NotFound();
    }
}
