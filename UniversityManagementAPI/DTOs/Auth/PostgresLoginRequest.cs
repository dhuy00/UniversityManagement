using System.ComponentModel.DataAnnotations;

public sealed class PostgresLoginRequest
{
    [Required]
    public string Username { get; init; } = string.Empty;

    [Required]
    public string Password { get; init; } = string.Empty;
}
