using System.ComponentModel.DataAnnotations;

public sealed class UpdateContactRequest
{
    [StringLength(20)]
    [RegularExpression(@"^\d*$", ErrorMessage = "Phone must contain digits only.")]
    public string? Phone { get; init; }

    [StringLength(500)]
    public string? Address { get; init; }
}
