using System.ComponentModel.DataAnnotations;

public sealed class SaveTeachingAssignmentRequest
{
    [Required]
    [StringLength(20)]
    public string LecturerId { get; init; } = string.Empty;

    [Required]
    [StringLength(20)]
    public string CourseId { get; init; } = string.Empty;

    [Range(1, 3)]
    public int Semester { get; init; }

    [Range(2000, 9999)]
    public int AcademicYear { get; init; }

    [Required]
    [RegularExpression("^(REGULAR|HIGH_QUALITY|ADVANCED|VIETNAM_FRANCE)$")]
    public string ProgramId { get; init; } = string.Empty;
}
