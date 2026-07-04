using System.ComponentModel.DataAnnotations;

public sealed class SaveCoursePlanRequest
{
    [Required]
    [StringLength(20)]
    public string CourseId { get; init; } = string.Empty;

    [Range(1, 3)]
    public int Semester { get; init; }

    [Range(2000, 9999)]
    public int AcademicYear { get; init; }

    [Required]
    [RegularExpression(
        "^(REGULAR|HIGH_QUALITY|ADVANCED|VIETNAM_FRANCE)$",
        ErrorMessage = "Program is not supported.")]
    public string ProgramId { get; init; } = string.Empty;
}
