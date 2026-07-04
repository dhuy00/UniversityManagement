using System.ComponentModel.DataAnnotations;

public sealed class CreateStudentRequest
{
    [Required]
    [StringLength(20)]
    public string StudentId { get; init; } = string.Empty;

    [Required]
    [StringLength(150)]
    public string FullName { get; init; } = string.Empty;

    [Required]
    [RegularExpression("^(MALE|FEMALE|OTHER)$")]
    public string Gender { get; init; } = string.Empty;

    public DateTime DateOfBirth { get; init; }

    [StringLength(500)]
    public string? Address { get; init; }

    [StringLength(20)]
    public string? Phone { get; init; }

    [Required]
    [RegularExpression("^(REGULAR|HIGH_QUALITY|ADVANCED|VIETNAM_FRANCE)$")]
    public string ProgramId { get; init; } = string.Empty;

    [Required]
    [RegularExpression("^(IS|SE|CS|IT|CV|NET)$")]
    public string MajorId { get; init; } = string.Empty;

    [Range(0, 300)]
    public int AccumulatedCredits { get; init; }

    [Range(typeof(decimal), "0", "10")]
    public decimal CumulativeGpa { get; init; }

    [Required]
    [RegularExpression("^[A-Z][A-Z0-9_$#]{0,127}$")]
    public string OracleUsername { get; init; } = string.Empty;

    [Required]
    [RegularExpression("^(CAMPUS_1|CAMPUS_2)$")]
    public string CampusId { get; init; } = string.Empty;
}
