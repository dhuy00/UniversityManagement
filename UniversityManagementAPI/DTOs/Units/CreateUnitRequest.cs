using System.ComponentModel.DataAnnotations;

public sealed class CreateUnitRequest
{
    [Required]
    [StringLength(20)]
    public string UnitId { get; init; } = string.Empty;

    [Required]
    [StringLength(150)]
    public string UnitName { get; init; } = string.Empty;
}
