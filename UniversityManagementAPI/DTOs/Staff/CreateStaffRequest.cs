using System.ComponentModel.DataAnnotations;

public sealed class CreateStaffRequest
{
    [Required]
    [StringLength(20)]
    public string StaffId { get; init; } = string.Empty;

    [Required]
    [StringLength(150)]
    public string FullName { get; init; } = string.Empty;

    [Required]
    [RegularExpression("^(MALE|FEMALE|OTHER)$")]
    public string Gender { get; init; } = string.Empty;

    public DateTime DateOfBirth { get; init; }

    [Range(typeof(decimal), "0", "9999999999.99")]
    public decimal Allowance { get; init; }

    [StringLength(20)]
    [RegularExpression(@"^\d*$", ErrorMessage = "Phone must contain digits only.")]
    public string? Phone { get; init; }

    [Required]
    [RegularExpression(
        "^(BASIC_STAFF|LECTURER|ACADEMIC_AFFAIRS|UNIT_HEAD|DEAN)$")]
    public string RoleCode { get; init; } = string.Empty;

    [Required]
    [StringLength(20)]
    public string UnitId { get; init; } = string.Empty;

    [Required]
    [RegularExpression("^[A-Z][A-Z0-9_$#]{0,127}$")]
    public string OracleUsername { get; init; } = string.Empty;

    [Required]
    [RegularExpression("^(CAMPUS_1|CAMPUS_2)$")]
    public string CampusId { get; init; } = string.Empty;
}
