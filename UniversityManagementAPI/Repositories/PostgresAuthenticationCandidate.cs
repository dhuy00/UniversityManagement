public sealed record PostgresAuthenticationCandidate(
    long UserId,
    string Username,
    string PasswordHash,
    IReadOnlyList<string> RoleCodes,
    string? IdentityType,
    string? StaffId,
    string? StudentId,
    string? UnitId,
    string? ProgramId,
    string? MajorId,
    string? CampusId);
