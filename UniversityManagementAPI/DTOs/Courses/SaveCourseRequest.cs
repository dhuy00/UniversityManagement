using System.ComponentModel.DataAnnotations;

public sealed class SaveCourseRequest : IValidatableObject
{
    [Required]
    [StringLength(20)]
    public string CourseId { get; init; } = string.Empty;

    [Required]
    [StringLength(200)]
    public string CourseName { get; init; } = string.Empty;

    [Range(1, 10)]
    public int Credits { get; init; }

    [Range(0, 1000)]
    public int TheoryPeriods { get; init; }

    [Range(0, 1000)]
    public int PracticePeriods { get; init; }

    [Range(1, 1000)]
    public int MaxStudents { get; init; }

    [Required]
    [StringLength(20)]
    public string UnitId { get; init; } = string.Empty;

    public IEnumerable<ValidationResult> Validate(
        ValidationContext validationContext)
    {
        if (TheoryPeriods + PracticePeriods == 0)
        {
            yield return new ValidationResult(
                "At least one theory or practice period is required.",
                [nameof(TheoryPeriods), nameof(PracticePeriods)]);
        }
    }
}
