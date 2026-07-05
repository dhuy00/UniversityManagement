public sealed class TeachingAssignmentDto
{
    public string LecturerId { get; init; } = string.Empty;
    public string CourseId { get; init; } = string.Empty;
    public string CourseName { get; init; } = string.Empty;
    public string UnitId { get; init; } = string.Empty;
    public int Semester { get; init; }
    public int AcademicYear { get; init; }
    public string ProgramId { get; init; } = string.Empty;
}
