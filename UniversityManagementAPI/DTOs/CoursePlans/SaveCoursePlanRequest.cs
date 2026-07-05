using System.ComponentModel.DataAnnotations;

public sealed class SaveCoursePlanRequest : IValidatableObject
{
    [Required]
    [StringLength(20)]
    public string CourseId { get; init; } = string.Empty;

    [Range(1, 3)]
    public int Semester { get; init; }

    [Range(2000, 9999)]
    public int AcademicYear { get; init; }

    public DateTime StartDate { get; init; }

    [Required]
    [RegularExpression(
        "^(REGULAR|HIGH_QUALITY|ADVANCED|VIETNAM_FRANCE)$",
        ErrorMessage = "Program is not supported.")]
    public string ProgramId { get; init; } = string.Empty;

    public IEnumerable<ValidationResult> Validate(
        ValidationContext validationContext)
    {
        if (StartDate == default)
        {
            yield return new ValidationResult(
                "Start date is required.",
                [nameof(StartDate)]);
        }
        else if (StartDate.Year != AcademicYear)
        {
            yield return new ValidationResult(
                "Start date must be inside the academic year.",
                [nameof(StartDate), nameof(AcademicYear)]);
        }
    }
}
