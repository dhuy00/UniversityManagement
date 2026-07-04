using System.ComponentModel.DataAnnotations;

public sealed class UpdateEnrollmentScoresRequest
{
    [Required]
    public string StudentId { get; init; } = string.Empty;

    [Required]
    public string LecturerId { get; init; } = string.Empty;

    [Required]
    public string CourseId { get; init; } = string.Empty;

    [Range(1, 3)]
    public int Semester { get; init; }

    [Range(2000, 9999)]
    public int AcademicYear { get; init; }

    [Required]
    public string ProgramId { get; init; } = string.Empty;

    [Range(0, 10)]
    public decimal? PracticeScore { get; init; }

    [Range(0, 10)]
    public decimal? ProcessScore { get; init; }

    [Range(0, 10)]
    public decimal? FinalExamScore { get; init; }

    [Range(0, 10)]
    public decimal? FinalScore { get; init; }
}
