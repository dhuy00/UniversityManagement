using System.ComponentModel.DataAnnotations;

public sealed class UpdateUnitRequest
{
    [Required]
    [StringLength(150)]
    public string UnitName { get; init; } = string.Empty;
}
