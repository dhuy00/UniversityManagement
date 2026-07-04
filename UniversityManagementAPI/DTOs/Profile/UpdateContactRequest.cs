using System.ComponentModel.DataAnnotations;

public sealed class UpdateContactRequest
{
    [StringLength(20)]
    public string? Phone { get; init; }

    [StringLength(500)]
    public string? Address { get; init; }
}
