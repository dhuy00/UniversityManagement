using System.ComponentModel.DataAnnotations;

public sealed class LoginRequest
{
    [Required]
    [RegularExpression(
        "^[A-Za-z][A-Za-z0-9_$#]{0,127}$",
        ErrorMessage = "Username is not a valid Oracle identifier.")]
    public string Username { get; init; } = string.Empty;

    [Required]
    public string Password { get; init; } = string.Empty;
}
