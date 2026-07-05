public sealed class StaffDto
{
    public string StaffId { get; init; } = string.Empty;
    public string FullName { get; init; } = string.Empty;
    public string Gender { get; init; } = string.Empty;
    public DateTime DateOfBirth { get; init; }
    public decimal Allowance { get; init; }
    public string? Phone { get; init; }
    public string RoleCode { get; init; } = string.Empty;
    public string UnitId { get; init; } = string.Empty;
    public string OracleUsername { get; init; } = string.Empty;
    public string CampusId { get; init; } = string.Empty;
}
