public sealed class StudentDto
{
    public string StudentId { get; init; } = string.Empty;
    public string FullName { get; init; } = string.Empty;
    public string Gender { get; init; } = string.Empty;
    public DateTime DateOfBirth { get; init; }
    public string? Address { get; init; }
    public string? Phone { get; init; }
    public string ProgramId { get; init; } = string.Empty;
    public string MajorId { get; init; } = string.Empty;
    public int AccumulatedCredits { get; init; }
    public decimal CumulativeGpa { get; init; }
    public string CampusId { get; init; } = string.Empty;
}
