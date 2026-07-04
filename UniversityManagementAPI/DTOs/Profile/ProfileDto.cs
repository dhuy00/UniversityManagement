public sealed class ProfileDto
{
    public string Id { get; init; } = string.Empty;
    public string FullName { get; init; } = string.Empty;
    public string Gender { get; init; } = string.Empty;
    public DateTime DateOfBirth { get; init; }
    public string? Phone { get; init; }
    public string IdentityType { get; init; } = string.Empty;
    public string? RoleCode { get; init; }
    public string? UnitId { get; init; }
    public string? UnitName { get; init; }
    public string? ProgramId { get; init; }
    public string? MajorId { get; init; }
    public string CampusId { get; init; } = string.Empty;
    public string? Address { get; init; }
    public decimal? Allowance { get; init; }
    public int? AccumulatedCredits { get; init; }
    public decimal? CumulativeGpa { get; init; }
}
