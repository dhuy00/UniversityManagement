public sealed record LoginResponse(
    string AccessToken,
    DateTimeOffset ExpiresAt,
    AuthenticatedUser User);

public sealed record AuthenticatedUser(
    string Username,
    string IdentityType,
    string RoleCode,
    string? StaffId,
    string? StudentId);
