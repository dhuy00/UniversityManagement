public sealed class EnrollmentDto
{
    public string StudentId { get; init; } = string.Empty;
    public string StudentName { get; init; } = string.Empty;
    public string LecturerId { get; init; } = string.Empty;
    public string CourseId { get; init; } = string.Empty;
    public string CourseName { get; init; } = string.Empty;
    public int Semester { get; init; }
    public int AcademicYear { get; init; }
    public string ProgramId { get; init; } = string.Empty;
    public decimal? PracticeScore { get; init; }
    public decimal? ProcessScore { get; init; }
    public decimal? FinalExamScore { get; init; }
    public decimal? FinalScore { get; init; }
}
