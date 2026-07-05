public sealed class RegistrationOptionDto
{
    public string LecturerId { get; init; } = string.Empty;
    public string CourseId { get; init; } = string.Empty;
    public string CourseName { get; init; } = string.Empty;
    public int Semester { get; init; }
    public int AcademicYear { get; init; }
    public string ProgramId { get; init; } = string.Empty;
    public DateTime StartDate { get; init; }
    public bool RegistrationOpen { get; init; }
}
