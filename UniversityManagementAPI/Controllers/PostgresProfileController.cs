using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Npgsql;
using UniversityManagementAPI.Repositories.Interfaces;

namespace UniversityManagementAPI.Controllers;

[ApiController]
[Authorize]
[Route("api/pg/profile")]
public sealed class PostgresProfileController : ControllerBase
{
    private readonly IPostgresRequestTransaction _transaction;
    private readonly IPostgresProfileRepository _profileRepository;

    public PostgresProfileController(
        IPostgresRequestTransaction transaction,
        IPostgresProfileRepository profileRepository)
    {
        _transaction = transaction;
        _profileRepository = profileRepository;
    }

    [HttpGet]
    public async Task<IActionResult> GetCurrent(CancellationToken cancellationToken)
    {
        var userId = _transaction.UserId;
        var (identityType, identityId) = await ResolveIdentityAsync(userId, cancellationToken);

        if (identityType is null || identityId is null)
            return Forbid();

        var profile = identityType switch
        {
            "STAFF" => await _profileRepository.GetStaffProfileAsync(identityId, cancellationToken),
            "STUDENT" => await _profileRepository.GetStudentProfileAsync(identityId, cancellationToken),
            _ => null
        };

        return profile is null ? NotFound() : Ok(profile);
    }

    [HttpPut("contact")]
    public async Task<IActionResult> UpdateContact(
        [FromBody] UpdateContactRequest request,
        CancellationToken cancellationToken)
    {
        var userId = _transaction.UserId;
        var (identityType, identityId) = await ResolveIdentityAsync(userId, cancellationToken);

        if (identityType is null || identityId is null)
            return Forbid();

        var updated = await _profileRepository.UpdateContactAsync(
            identityType,
            identityId,
            request,
            cancellationToken);

        return updated ? NoContent() : NotFound();
    }

    private async Task<(string? IdentityType, string? IdentityId)> ResolveIdentityAsync(
        long userId,
        CancellationToken cancellationToken)
    {
        const string staffSql = """
            SELECT staff_id FROM university.staff WHERE user_id = $1
            """;
        await using var staffCmd = new NpgsqlCommand(staffSql, _transaction.Connection, _transaction.Transaction);
        staffCmd.Parameters.AddWithValue(userId);
        await using var staffReader = await staffCmd.ExecuteReaderAsync(cancellationToken);
        if (await staffReader.ReadAsync(cancellationToken))
        {
            var staffId = staffReader.GetString(0);
            return ("STAFF", staffId);
        }

        const string studentSql = """
            SELECT student_id FROM university.students WHERE user_id = $1
            """;
        await using var studentCmd = new NpgsqlCommand(studentSql, _transaction.Connection, _transaction.Transaction);
        studentCmd.Parameters.AddWithValue(userId);
        await using var studentReader = await studentCmd.ExecuteReaderAsync(cancellationToken);
        if (await studentReader.ReadAsync(cancellationToken))
        {
            var studentId = studentReader.GetString(0);
            return ("STUDENT", studentId);
        }

        return (null, null);
    }
}
