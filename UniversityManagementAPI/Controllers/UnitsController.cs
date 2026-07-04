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
}
