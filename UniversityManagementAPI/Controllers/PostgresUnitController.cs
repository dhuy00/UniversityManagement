using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using UniversityManagementAPI.Repositories.Interfaces;

namespace UniversityManagementAPI.Controllers;

[ApiController]
[Authorize(Roles = "BASIC_STAFF,LECTURER,ACADEMIC_AFFAIRS,UNIT_HEAD,DEAN")]
[Route("api/pg/unit")]
public sealed class PostgresUnitController : ControllerBase
{
    private readonly IPostgresUnitRepository _unitRepository;

    public PostgresUnitController(IPostgresUnitRepository unitRepository)
    {
        _unitRepository = unitRepository;
    }

    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<UnitDto>>> GetAll(
        CancellationToken cancellationToken)
    {
        var units = await _unitRepository.GetAllAsync(cancellationToken);
        return Ok(units);
    }

    [Authorize(Roles = "ACADEMIC_AFFAIRS")]
    [HttpPost]
    public async Task<IActionResult> Create(
        [FromBody] CreateUnitRequest request,
        CancellationToken cancellationToken)
    {
        await _unitRepository.CreateAsync(request, cancellationToken);
        return NoContent();
    }

    [Authorize(Roles = "ACADEMIC_AFFAIRS")]
    [HttpPut("{unitId}")]
    public async Task<IActionResult> Update(
        [FromRoute] string unitId,
        [FromBody] UpdateUnitRequest request,
        CancellationToken cancellationToken)
    {
        var updated = await _unitRepository.UpdateAsync(
            unitId,
            request,
            cancellationToken);

        return updated ? NoContent() : NotFound();
    }
}
